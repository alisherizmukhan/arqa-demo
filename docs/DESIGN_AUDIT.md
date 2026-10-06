# Design audit — current app vs DESIGN.md (variant A)

Stage 1 of the redesign. **No code changed.** Sources: `DESIGN.md` (read in full), the 12 screen mockups and
2 kit sheets in `docs/design/` (measured at @2x, ÷2 = dp), and the current app (stage-5 web build) captured at
exactly 390×844 @2x through headless Edge + DevTools device emulation.
Side-by-side images (mockup left, current right): `docs/design/audit/sbs_*.png`.

Legend: ✅ already matches · ❌ to do (stage in brackets) · ⚠️ conflict / decision — see the end of this file.

Summary: the current UI is the stage-4 kit (IBM Plex Sans, green accent, Material icons) and matches **none**
of the visual spec. Domain, data layer, API and most behaviour are reusable as-is.

---

## 1. Tokens (`packages/design_kit`) — stage 2

| Item | Current | Spec | |
|---|---|---|---|
| DkColors: 31 tokens × light/dark (§2.1) | 17 different tokens (green accent `#15803D`/`#22C55E`, OLED `#020617`) | bg `#F4F5F7`/`#0B0D10`, accent `#2450D8`/`#7B9BFF`, inverse*, split*, scrim… | ❌ [2] |
| Token names | `primary`, `positive`, `cash`, `card`, `outline`… | `accent`, `accentSoft`, `segmentTrack/Thumb`, `textTertiary`, `textDisabled`, `iconDisabled`, `inverse*`, `skeleton`, `splitNeutral`, `disabledFill`, `scrim` | ❌ [2] |
| Font | IBM Plex Sans (variable) | **Manrope 500/600/700/800**, bundled `.ttf` in the kit, `packages/design_kit/Manrope` | ❌ [2] ⚠️ F |
| Tabular figures in every style | Plex digits tabular by default; no `fontFeatures` | `FontFeature.tabularFigures()` on every style (Manrope digits are proportional: 716–1240 units) | ❌ [2] |
| DkTypography: 18 styles (§2.2) | 8 styles (moneyHero 44/700, moneyLarge 26…) | moneyHero 44/48 w800 −0.88, moneyHeroSuffix, titleL, moneyL, wordmark, titleDialog, fieldTime, titleM, moneyM, bodyStrong, body, bodyMd, bodyS, label, captionStrong, caption, badge, superscript | ❌ [2] |
| DkSpacing | `xxs…xxl` (4…48) | `s2…s64` (14 steps) + `screenGutter = 16` | ❌ [2] |
| DkRadii | sm 8 / md 12 / lg 16 / pill | xs 4, sm 8, segment 10, md 12, segmentTrack 14, lg 16, xl 24, pill 999 | ❌ [2] |
| DkElevation (light only; dark none) | does not exist (flat cards with borders) | e1, e1Hero, e2Fab, e3, thumb | ❌ [2] |
| DkSizes | 8 sizes (control 56, row 64…) | tapTargetMin 48, buttonHeight 56/48, fieldHeight, segmentedHeight, daySwitcherHeight 56, tripTileMinHeight 72, iconTile 40/22, stateIconTile 80/36, dialogIconTile 56/28, splitBar 8/gap 3, icon sizes 24/22/20/16, fieldBorder 1/2, focusRing 4 | ❌ [2] |
| `context.dkColors/dkText/…` accessors | ✅ exist (pattern kept) | same | ✅ |
| `DkTheme.light()/dark()` | ✅ exist | rebuilt from new tokens | ❌ [2] |
| Icons | Material outlined | **Lucide** (`lucide_icons_flutter` 3.1.22), stroke 2 (2.4 plus/chevron-down, 2.2 inline error), mapping §2.7 | ❌ [3] |
| `packages/design_kit/DESIGN.md` | stage-4 rationale (IBM Plex) | copy of root `DESIGN.md` | ❌ [2] |

## 2. Components — stage 3

| Component | Current | Spec (§4) | |
|---|---|---|---|
| DkButton | primary/secondary/text; 56 high, radius 12, secondary = outlined | primary accent; **secondary = accentSoft bg + accent fg**; text h48 radius md; radius lg; padding 24 (20 icon side); disabled `disabledFill`/`textDisabled`; loading spinner 20 stroke 2.6 + «Сохраняем…», `Semantics(busy)` | ❌ |
| DkFab | — | pill, 56, `e2Fab`, right 16 / bottom safe+16 | ❌ new |
| DkCard | border, radius 16, no shadow | no border, shadow e1 (`hero` → e1Hero), radius param | ❌ |
| DkSummaryCard | — (app-level SummaryCard) | hero card padding 20 r24: «На руки» → hero → divider → 3 tiles | ❌ new |
| DkSummaryTile | `.money/.count`, tones, FittedBox | `label/value/icon?/hint?`, plain and payment-tile variant (icon tile 40) | ❌ |
| DkSplitBar | — | h8, gap 3, cash `splitNeutral` / card `accent`, semantics «Наличные 38%, карта 62%» | ❌ new |
| DkTripTile | icon badge 48, meta «Карта · комиссия», amount right | min 72, icon tile 40, time `bodyStrong` + «+1» superscript, meta «22 мин · Карта», amount + «комиссия 360 ₸» right, `highlighted` (accentSoft ~2 s), dividers inset 68 | ❌ |
| DkDaySwitcher | one-line label with calendar icon, no card | card h56 r16 e1, 48×48 chevrons, title `titleM` + chevron-down 16 / subtitle `caption`; takes `DateTime date/today`; semantics «Выбрать дату, 1 октября 2026» | ❌ |
| DkTextField | label above, Material decoration, error text only | border 1 → 2 + 4 px accentSoft ring on focus (padding 15→14), error row with circle-alert 16, disabled colours, **time** and **money** variants, `trailing` slot | ❌ |
| DkBadge | — | h24 r8 accentSoft/accent `badge` | ❌ new |
| DkSegmentedControl | two separate 56 dp buttons, selected = filled green | track `segmentTrack` r14 p4, thumb `segmentThumb` r10 + shadow, animated 200 ms, radio-group semantics | ❌ |
| DkSnackbar (`showDkSnackbar`) | Material SnackBar from theme | error/info full-width with action; compact success bottom-left beside the FAB, 3 s | ❌ new |
| DkDialog (`showDkDialog`) | — | scrim, r24, icon tile 56, title, message, stacked buttons | ❌ new |
| DkEmptyState / DkErrorState | small icon, no tile; empty has optional secondary button | icon tile 80 r24 (route / cloud-off), `titleL`, `body`, primary button with icon; error = live region, `isRetrying` | ❌ |
| DkSkeleton | single block, pulse 1.2 s | `.line/.box` + composites `.summaryCard/.paymentCard/.tripTile`, pulse 1 → 0.55 → 1, 1.4 s; off under reduced motion | ❌ (reduced-motion ✅) |
| Example app | every stage-4 component, light/dark toggle | every component **in every state**, light + dark | ❌ |
| Golden tests | none (stage-4 decision) | alchemist goldens for the §7 list | ❌ ⚠️ G |

## 3. Screens — stage 4

### Day (`01`, `02`) — see `sbs_01_day_light.png`, `sbs_02_day_dark.png`
- ❌ Header: Material AppBar «Дневник смены» → wordmark row h48: 12×12 accent square r4 + «Дневник смен» `wordmark`.
- ❌ Day switcher: one line «Чт, 1 октября» with calendar icon → card with «1 октября 2026 ⌄ / Четверг».
- ❌ Summary: «Чистыми» green, cash/card and trip count inside the card → «На руки» accent hero; Выручка / Комиссия / Поездок in a 3-column row.
- ❌ Payment card (two payment tiles + split bar) — missing.
- ❌ Trips header «Поездки» + «2 поездки · 37 мин» — missing.
- ❌ Trip rows — see DkTripTile. Current meta wraps to 2 lines at 390 dp («Наличные · комиссия / 225 ₸»).
- ❌ «Добавить поездку» full-width bottom button → DkFab «+ Поездка»; list bottom padding clears the FAB.
- ❌ No `RefreshIndicator` styling change needed; pull-to-refresh itself exists ✅.

### Add trip (`07`) — see `sbs_07_add_trip.png`
- ❌ Pushed page with back arrow → **full-screen modal** (`fullscreenDialog: true`), close «x» 48, centred title «Новая поездка» + date subtitle, right spacer 48.
- ❌ Date field exists → removed; the trip date is the day the form was opened for (subtitle). ⚠️ see «Lost capability»
- ❌ Fields: time fields with clock prefix, `fieldTime` style; helper «Длительность: 22 мин» under the row.
- ❌ «Сумма» / «Комиссия» money fields: `moneyL`, «₸» suffix, digits grouped with U+202F while typing; helpers «Сколько заплатил пассажир», «На руки с поездки: 2 040 ₸» (current helper «Сколько удержал сервис»).
- ❌ «Оплата» → «Способ оплаты» + new segmented control.
- ❌ Save in the scroll flow → pinned bottom bar (bg `bg`, top border `divider`, padding 12 16 + safe area).

## 4. States

| State | Mockup | Current | |
|---|---|---|---|
| Day — empty | `03` | summary of zeros + small empty block + bottom button | ❌ only DkEmptyState with «Добавить поездку», **no FAB**, no summary |
| Day — loading | `04` | generic skeleton | ❌ composite skeletons replicating the layout; FAB visible |
| Day — error | `05` | DkErrorState (different copy/visual) | ❌ copy + tile; **no FAB** |
| Day — refresh failure with data | §5.4 | full error screen replaces data | ❌ keep data + error DkSnackbar |
| Day — trip added | `06` | standard SnackBar «Поездка сохранена · 2 400 ₸» | ❌ highlighted row ~2 s + compact success snackbar beside the FAB ✅ switch to the trip's start day already works |
| Add — validation | `08` | errors after first Save, then live; Save always enabled | ❌ show after blur or Save; **Save disabled while errors exist**; error row with icon; red label/border |
| Add — saving | `09` | button spinner, payment disabled | ❌ all inputs disabled (surfaceMuted/divider), «Сохраняем…» |
| Add — offline | `10` | red banner above Save | ❌ DkSnackbar «Нет связи. Повторим отправку — поездка не задвоится.» + «Повторить»; **auto-retry 2 s, 4 s, 8 s, then every 30 s** with the same id ⚠️ R |
| Add — cross midnight | `11` | end < start → next day, helper «На следующий день»; end == start → error | ❌ end **≤** start → next day; DkBadge «+1 день»; helper «Окончание 1 октября · 30 мин. Поездка попадёт в 30 сентября — день начала.»; error only if duration 0 or > 12 h ⚠️ L |
| Add — conflict 409 | `12` | red banner «…уже сохранена с другими данными…» | ❌ DkDialog with stored values ⚠️ C |
| Add — close with unsaved input | §5.6 | closes silently | ❌ confirm discard |

## 5. Copy (§6) — stage 4/5

- ❌ Copy in one file (`core/l10n/strings_ru.dart`); today strings are spread across screens and kit defaults.
- ❌ «Дневник смены» → «Дневник смен»; «Чистыми» → «На руки»; «Оплата» → «Способ оплаты»; «Добавить поездку» (FAB) → «Поездка».
- ❌ Empty: «Поездок нет / За этот день ещё нет поездок.» → «За этот день поездок нет / Добавьте поездку — выручка, комиссия и сумма на руки посчитаются сами.»
- ❌ Error: «Не удалось загрузить / Нет связи с сервером…» → «Не удалось загрузить данные / Проверьте интернет и попробуйте ещё раз. Сохранённые поездки никуда не пропадут.»
- ❌ Validation: «Укажите сумму/комиссию/время…» → «Заполните поле»; «Сумма должна быть больше нуля» → «Сумма должна быть больше 0»; ✅ «Комиссия не может быть больше суммы», ✅ «Комиссия не может быть отрицательной», ✅ «Окончание должно быть позже начала».
- ❌ «Поездка сохранена · …» → «Поездка добавлена»; «Сохранить» ✅; loading label «Сохраняем…» new.
- ❌ Semantics labels: «Предыдущий день» ✅, «Следующий день» ✅, «Выбрать дату, 1 октября 2026» (now hint «Выбрать дату»), «Закрыть» new.

## 6. Formatting (§3) — one place: `design_kit/lib/src/format/`

| Rule | Current | |
|---|---|---|
| Money groups + before ₸ = **U+202F** | U+00A0 (`DkMoney`), tests assert U+00A0 | ❌ tests will be rewritten to assert U+202F ⚠️ T |
| Commission in summary `−585 ₸` (U+2212) | ✅ U+2212 | ✅ (re-test) |
| Hero = number span + `₸` span joined by U+202F | single string | ❌ |
| Time `HH:mm`, range `08:10 – 08:32` (en dash, spaces) | ✅ | ✅ (move into kit format) |
| Duration «22 мин» / «1 ч 5 мин» / «2 ч» | none | ❌ |
| Dates `1 октября 2026`, weekday capitalised «Четверг» | «Чт, 1 октября» | ❌ |
| Relative label: today → «Сегодня» + date; yesterday → «Вчера» + date; else date + weekday | «Сегодня, 6 октября» one line | ❌ |
| Plural поездка/поездки/поездок incl. 11–14 | none | ❌ |
| Split % largest-remainder, sum 100, hidden at revenue 0 | none | ❌ |
| Cross-midnight «23:50 – 00:20» + superscript «+1» | plain range | ❌ |
| Date formatting lives in `apps/mobile/lib/core/format` | must be **one place**; DkDaySwitcher takes `DateTime`, so it moves into the kit | ❌ ⚠️ D |

## 7. Quality gates (§7 + task)

- ❌ `grep -R "Color(0x\|Colors\.\|TextStyle(" apps/mobile/lib` in CI — today 0 hits for `Color(0x`/`Colors.` ✅, but no CI step; `TextStyle(` 0 hits ✅.
- ❌ No literal spacing/radii in `apps/mobile` (today: none found by the stage-5 grep ✅; re-check after rebuild).
- ❌ Golden tests (alchemist) for: DkSummaryCard, DkTripTile ×4, DkTextField ×3, DkButton matrix, DkDaySwitcher ×2, Day light + dark.
- ❌ Text scale 1.3: no clipping on Day and Add trip (widget tests).
- ✅ Tap targets ≥ 48 (guideline tests exist for the old kit; re-run on the new one).
- ✅ All existing tests green today (backend 194, kit 70, showcase 4, mobile 61).

---

## Conflicts and decisions to confirm

**PNG vs DESIGN.md — DESIGN.md wins** (also recorded in `docs/DECISIONS.md`):
1. `11_add_trip_midnight`: the end time is clipped by the badge («00:2(»). Spec + the 1.3 text-scale rule → no clipping; the time and badge must fit.
2. `12_add_trip_conflict_409`: the time fields behind the scrim have no clock prefix. Spec: the time variant always has it.
3. `09_add_trip_saving`: the amount helper disappears while saving. The spec says nothing about hiding helpers → keep it (no layout jump).
4. `13_kit_tokens`: «e1» is drawn as two shadows (= spec `e1Hero`); spacing named `space4…`; no xs/segment/segmentTrack radii. → spec names and values.
5. `14_kit_components`: different APIs (`DkButton.fab`, `DkSplitBar(parts:)`, `DkTripTile(start,end,duration…)`, `DkSummaryTile(emphasis:)`) and a shorter empty-state message. → spec APIs and §6 copy.
6. `09`: the disabled segmented thumb is a lighter tone that has no token → closest tokens (`segmentThumb` + `textSecondary` labels).

**Open points (my proposed resolution in bold — reply if you disagree):**
- **C — 409 stored values.** The backend's 409 body is `{"error":{"code":"trip_conflict","message":…,"field":"id"}}` — **no stored trip**. Per the task: dialog without values. **Alternative (no backend change):** after a 409, look the stored trip up with the existing `GET /trips?date=` for the attempt's day and show its values when found. Default: **without values** unless you say otherwise.
- **G — goldens across OSes.** Font rasterisation differs between Windows and the Linux CI runner. **alchemist "CI goldens" (text as blocks) run in CI; platform goldens with real fonts are generated locally for visual review and excluded from CI.**
- **F — Manrope has no `₸` (U+20B8) and no U+202F.** Without a fallback they render from whatever system font exists. **Bundle-only fallback: `fontFamilyFallback: [IBM Plex Sans]` (already in the kit, has both glyphs), used only for those two characters.** Manrope has no Reserved Font Name, so static 500/600/700/800 instances may be cut from the variable font.
- **H — fixed heights vs text scale 1.3.** Day switcher (title 24 + subtitle 16 line heights → 52 at 1.3 inside 56 − 8 padding), buttons, fields and segments are specified as fixed 56. **Treat them as minimum heights** so nothing clips at 1.3; at 1.0 they render exactly 56.
- **R — retries.** dio already retries transient errors (0.5 s, 2 s). With the spec's 2/4/8/30 s schedule on top, an offline save would wait ~30 s (3 × 10 s connect timeout) before the snackbar appears. **For POST from the form, turn off interceptor retries and let the form controller run the spec schedule (same id); GET keeps the interceptor.**
- **L — 12 h limit.** Client-side: error if duration is 0 or > 12 h; the server still allows ≤ 24 h. **Client stricter than server (presentation only); no domain or API change.**
- **D — date formatting location.** DkDaySwitcher receives `DateTime`, so Russian date formatting must live in the kit; **`apps/mobile/lib/core/format/date_format.dart` moves into `design_kit/lib/src/format/` (one place), and `apps/mobile` uses it from there.**
- **T — tests that encode old formatting/copy** (U+00A0, «Чистыми», «Укажите сумму»…) will be **updated to the spec** in the same commits; logic tests (domain, data, idempotency) stay unchanged and green.
- **P — `PaymentMethod` name.** DkTripTile's spec signature uses `PaymentMethod`, which is also the domain enum. **The kit uses `DkPaymentMethod`** (the kit must not depend on the app); the app maps.
- **Lost capability:** the form no longer has a date field, so a trip can only be added to the day currently open (as in the mockups). Moving to another day first remains possible.
