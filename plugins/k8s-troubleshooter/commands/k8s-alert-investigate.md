---
name: k8s-alert-investigate
description: Investigate a firing Kubernetes alert on Tim's OCI cluster — fetches details from alertmanager, runs alert-type kubectl probes, proposes a fix
argument-hint: "<alertname>"
---

The user is investigating Kubernetes alert: **$ARGUMENTS**

Invoke the `k8s-alert-investigate` skill (in this plugin) to drive the four-phase investigation:

1. Fetch the full alert payload from alertmanager via `ssh oci-cp`
2. Run the alert-type playbook (kubectl describe / logs / events / cert / pvc / probe ...)
3. Diagnose root cause + why-now + propose a concrete fix
4. Ask before applying any fix

If `$ARGUMENTS` is empty, ask the user which alertname they want to investigate, then list current firing alerts from alertmanager so they can pick.
