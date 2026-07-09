/**
 * 詞彙定本骨架（glossary SSOT）— 複製到你的專案後改成專案專屬內容。
 * 搭配 guard-test-template.ts 的防回歸 guard 使用。
 *
 * 哲學：
 *   - TERMS：canonical 定本詞，**非強制**引用。字串可直接寫定本字，由 guard 守不回歸即可。此表供撰寫/review 對照。
 *   - BANNED_TERMS：在 UI「永遠是錯」、且**任何程式碼語境都不會合法出現**的 token 才收
 *     （在地化錯字 / 他地用語、或帶連字號的文案專用字）。裸英文技術詞不收（會與識別字碰撞）。
 *
 * 語言 / house-style 政策（改成你的）：例如「UI 全 <locale>；保留專有名詞 A/B/C；保留規格技術縮寫 X/Y/Z」。
 */

export interface Term {
  /** 定本用詞 */
  canonical: string
  /** 應避免、應收斂為 canonical 的舊用詞 */
  avoid?: string[]
  /** 決策背景 / 出處 */
  note?: string
}

/** 定本詞（非強制；供撰寫與 review 對照）。把下面換成你的概念。 */
export const TERMS: Record<string, Term> = {
  // exampleConcept: {
  //   canonical: '定本詞',
  //   avoid: ['舊詞1', '舊詞2', 'OldEnglishTerm'],
  //   note: '為何是這個 + 出處',
  // },
}

export interface BannedTerm {
  /** 禁用字（會被 guard 掃描比對；必須零碰撞） */
  term: string
  /** 建議改用 */
  suggest: string
  /** 為何禁用 */
  why: string
}

export const BANNED_TERMS: BannedTerm[] = [
  // ── 他地用語 / 在地化錯字（在目標語系 UI 永遠是錯；均須零碰撞驗證）──
  // { term: '用戶', suggest: '使用者', why: '中國用語（zh-TW 範例）' },

  // ── 違反產品文案框架的字（若有，例如定價 paywall framing）──
  // 註：不 ban 過於常見、會誤傷的字。只 ban 零碰撞的具體片語。
  // { term: '付費才', suggest: '改用「[方案] 用於 [用途]」框架', why: 'paywall framing' },

  // ── 已決議要翻 / 收斂的英文行話（帶連字號者安全）──
  // { term: 'single-demo', suggest: '單次展示', why: '英文行話，全 <locale> 政策' },
]
