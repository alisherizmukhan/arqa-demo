# Промпт: стабильность интерфейса (длинные подписи, kk, крупный шрифт)

Использован 12 октября 2026 (этапы 1–4, затем релиз v2.0.1). Восстановлен дословно из сессии, в которой был вставлен.

```
UI stability pass. Problem: when a label is longer than its control (Kazakh texts, larger system font, narrow phones), buttons, chips, tabs and badges grow in height or width and push the layout around. Goal: every control keeps its size; text adapts inside it. Work on main with the usual rules (every commit green, tool/ci_local.sh before pushing, stop after each stage and wait for my "ok"). No backend changes.

────────────────────────────────────────
Stage 1 — Audit (no code changes) → docs/UI_STABILITY_AUDIT.md
Render every screen and every kit component state (ru and kk; 360×780 and 390×844; text scale 1.0, 1.15, 1.3) and measure every interactive control: DkButton (all variants), DkFab, DkSegmentedControl / tabs, DkFilterChips, DkLanguageSwitch, DkBadge, DkStatusChip, DkIconButton, list rows, dialog buttons, snackbar actions, day switcher, text fields.
For each control record: designed size (DESIGN.md), actual size, whether the label wraps, is clipped, ellipsized or overflows, and where. List every case where a control's size depends on its label. Include screenshots of the worst cases (before).

────────────────────────────────────────
Stage 2 — Rules → add DESIGN.md §10 «Layout stability» (root + kit copy), then implement in the kit:
1. System text scale is clamped app-wide to max 1.3 (MediaQuery.withClampedTextScaling). Below that, everything follows the rules below.
2. Height is fixed, never content-driven, for: DkButton 56 (text 48), DkFab 56, DkSegmentedControl/tabs 56, DkFilterChips 40 (tap area 48), DkLanguageSwitch 56, DkBadge 24, DkStatusChip 24, DkIconButton 48, text fields 56, day switcher 56.
3. Labels inside these controls are always ONE line: maxLines 1, softWrap false. If the label does not fit, it first scales down (FittedBox scaleDown) to at most 85 % of its style size; if it still does not fit, it ends with an ellipsis and the full text goes to Semantics label and a tooltip/long-press. Never wrap, never grow.
4. Width: full-width buttons stay full width; inline buttons (FAB, empty/error state action, «Всё») get a maxWidth (FAB ≤ 60 % of screen width, inline ≤ 100 % of the content column) and follow rule 3 inside it.
5. Segmented controls/tabs: segments share the width equally (Expanded), each label follows rule 3. Filter chips scroll horizontally and never wrap to a second row.
6. Multi-line is allowed only for body text, messages, helpers, errors and list subtitles — never for controls. Dialog buttons follow rule 3 (this replaces the earlier two-line rule for «Сохранить как новую поездку»).
7. Rows that contain money keep the amount on one line (amount never shrinks below 85 %; the left text column ellipsizes first).
8. Kazakh copy: where a kk label hits the ellipsis at 360 dp / scale 1.0, propose a shorter kk wording in docs/L10N.md (mark «предложено») instead of relying on the ellipsis.

────────────────────────────────────────
Stage 3 — Fix every finding from the audit using the kit rules (no per-screen hacks). Update goldens.

────────────────────────────────────────
Stage 4 — Guard it with tests so it can't come back:
- Size-invariance test: for each control, render with a short label and with a very long label (e.g. 3× the longest real label) in ru and kk at text scale 1.0 and 1.3 — the control's size must be identical; no RenderFlex overflow; label is one line.
- Screen layout test (existing 360/390 × 1.0/1.3 × ru/kk matrix) additionally fails if any control from rule 2 differs from its designed height.
- Add text scale 1.15 to the matrix.

Report: before/after screenshots of the worst cases (review page), list of shortened kk labels for my approval, test counts. Then deploy nothing (client-only); build a new APK only when I say so.
```
