---
name: k8s-alert-investigate
description: >-
  Use when the user triggers a Homepage alertmanager deep link, runs
  `/k8s-alert-investigate <alertname>`, or asks to "diagnose alert",
  "investigate alert", "為什麼這個 alert 在響", "查 alert", or describes a
  firing Kubernetes alert on the OCI cluster (alertname like
  KubePodCrashLooping, IngressProbeFailing, KubeContainerOOMKilled,
  CertManagerCertificateExpiringSoon, etc.). Pulls full alert details
  from alertmanager via ssh oci-cp, fetches relevant kubectl context
  based on alert type, identifies root cause, and proposes a fix.
  Skip if the user is asking general K8s questions unrelated to a
  specific firing alert.
---

# Kubernetes alert investigator

Diagnose a firing Prometheus/Alertmanager alert on Tim's self-hosted OCI K8s cluster, root-cause it, and propose a fix.

## Context you can rely on

- Cluster access: `ssh oci-cp kubectl ...` (never direct kubectl from local)
- Alertmanager service: `alertmanager.alertmanager.svc:9093` (in-cluster), `https://alertmanager.teachers-assist.com` (external)
- Prometheus rules live in: `apps/prometheus/rules.yaml` in `tim80411/k8s-apps` repo
- Event source (if installed): `kubernetes-event-exporter` in namespace `event-exporter` translates K8s Warning events into alerts with `source=k8s-event`

## Inputs

The deep link or user passes an alertname (e.g. `IngressProbeFailing`) as `$ARGUMENTS`. If only alertname is given, fetch labels/annotations yourself in Phase 1.

## Phase 1 — Fetch full alert payload

Always start here. Don't guess from alertname alone.

```bash
ssh oci-cp "kubectl exec -n alertmanager deploy/alertmanager -c alertmanager -- \
  wget -qO- 'http://localhost:9093/api/v2/alerts?silenced=false&inhibited=false'"
```

Filter the JSON array to the entry whose `labels.alertname` matches. Capture:

- `labels.*` (alertname, namespace, severity, instance, pod, node, deployment, persistentvolumeclaim, source, ...)
- `annotations.summary`, `annotations.description`
- `startsAt`, `status.state`
- `generatorURL` (the Prometheus expression — sometimes the root cause is visible directly there)

If no entry matches, the alert has resolved between deep-link click and now. Tell the user and stop.

## Phase 2 — Pull relevant context (alert-type playbook)

Match the alertname to the right kubectl probe. Always run these via `ssh oci-cp "..."`.

| Alert(s) | Commands to run |
|---|---|
| `KubePodCrashLooping`, `KubePodNotReady`, `KubeContainerOOMKilled` | `kubectl -n {namespace} describe pod {pod}`<br>`kubectl -n {namespace} logs {pod} --tail=200 --all-containers --previous`<br>`kubectl -n {namespace} logs {pod} --tail=200 --all-containers` |
| `KubeNodeNotReady`, `KubeNodeUnreachable`, `HostHighMemoryUsage`, `HostHighLoadAverage`, `HostDiskAlmostFull` | `kubectl describe node {node}`<br>`kubectl top node {node}`<br>`kubectl get pods --all-namespaces -o wide --field-selector spec.nodeName={node}` |
| `KubeDeploymentReplicasMismatch` | `kubectl -n {namespace} describe deploy {deployment}`<br>`kubectl -n {namespace} get rs -l app={deployment}`<br>`kubectl -n {namespace} get events --sort-by=.lastTimestamp \| tail -30` |
| `KubePersistentVolumeAlmostFull` | `kubectl -n {namespace} describe pvc {persistentvolumeclaim}`<br>`kubectl -n {namespace} get pods -o wide \| grep {persistentvolumeclaim}` (find the consumer) |
| `CertManagerCertificateExpiringSoon`, `CertManagerCertificateNotReady` | `kubectl -n {namespace} describe certificate {name}`<br>`kubectl -n {namespace} describe certificaterequest`<br>`kubectl -n {namespace} describe order`<br>`kubectl -n {namespace} describe challenge` |
| `IngressProbeFailing`, `IngressTLSExpiringSoon` | Try the URL: `curl -sIv {labels.instance}` (run locally — exits Tailscale via DNS, so most external).<br>If 5xx: `ssh oci-cp "kubectl get ingress -A \| grep {host}; kubectl -n {ns of backend} logs deploy/{backend} --tail=200"`.<br>Check blackbox-exporter rendition: `ssh oci-cp "kubectl -n blackbox-exporter logs deploy/blackbox-exporter --tail=100"` |
| `source=k8s-event` (events surfaced by event-exporter) | The `annotations.message`, `annotations.reason`, `labels.involved_object_kind`, `labels.involved_object_name` already have the K8s Event payload. Use it directly. May still need a `kubectl describe` on the involved object. |
| Anything else | `kubectl get all -n {namespace}`<br>Last 30 events in the namespace<br>Read the Prometheus expression from `generatorURL` and evaluate manually |

Don't run more than 3-4 commands before pausing to reason. Quality > volume.

## Phase 3 — Root cause + fix proposal

Frame the answer in three short sections:

1. **Root cause (1-2 sentences)** — pinpoint the thing that's wrong. Cite the evidence (which log line, which describe field, which exit code).
2. **Why it's firing now** — what specifically tripped the Prometheus expression. Helps tell "real problem" vs "noisy rule".
3. **Fix proposal** — concrete next steps. If it's a code/config fix in `k8s-apps`, say which file/path. If it's a transient cluster issue (e.g. evicted pod), say so and decide if the alert rule itself needs tightening to avoid the noise.

Never silently fix without proposing. The user reads the proposal first, then says "do it".

## Out of scope

- Don't propose fixes that need access you don't have (`oci-cli` is local only — don't claim you'll change OCI infrastructure unless user invokes the `oracle-cloud` workspace).
- Don't edit Prometheus rules without showing the diff first.
- If the alert is in a namespace you have no app for in `k8s-apps`, the cause may be controller-installed (e.g. nginx-ingress, cert-manager itself, sealed-secrets). Note that and check `argocd/` for the install Application before touching anything.

## Quick checklist (run as todos)

- [ ] Phase 1 — fetched alert payload, confirmed it's still firing
- [ ] Phase 2 — ran type-appropriate kubectl probes
- [ ] Phase 3 — root cause + why-now + fix proposal written
- [ ] Asked user before applying any fix
