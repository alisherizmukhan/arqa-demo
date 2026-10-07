# Дневник смен — Design Spec (variant A)

Single source of truth for `packages/design_kit`. Implement **exactly** these values.
Do not invent colors, sizes, radii or copy. If something is missing here, use the closest
existing token and record the decision in `docs/DECISIONS.md`.

Reference mockups: Design canvas «Дневник смен», page «Экраны», rows «Экран дня» and
«Добавление поездки» (variant A only — ignore variants B and C), page «Дизайн-кит».
Exported PNGs live in `docs/design/` at **@2x** (780×1688 px = 390×844 dp; divide every measured pixel by 2):

| File | Screen (§) |
|---|---|
| `01_day_light.png` | 5.1 Day, light |
| `02_day_dark.png` | 5.1 Day, dark |
| `03_day_empty.png` | 5.2 Empty |
| `04_day_loading.png` | 5.3 Loading |
| `05_day_error.png` | 5.4 Error |
| `06_day_trip_added.png` | 5.5 Trip added |
| `07_add_trip.png` | 5.6 Add trip form |
| `08_add_trip_errors.png` | 5.7 Validation |
| `09_add_trip_saving.png` | 5.8 Saving |
| `10_add_trip_offline.png` | 5.9 No connection |
| `11_add_trip_midnight.png` | 5.10 Cross midnight |
| `12_add_trip_conflict_409.png` | 5.11 Conflict 409 |

All px values below map 1:1 to Flutter logical pixels (dp).

---

## 1. Principles

1. Glanceable: the net payout («На руки») is the largest element on the Day screen.
2. One accent color: primary actions, «На руки», focus, selected state. Semantic colors only for error/success.
3. Meaning is never color-only: payment method = icon + text; errors = icon + text + border.
4. Tap targets ≥ 48 dp everywhere.
5. All numbers use tabular figures (`FontFeature.tabularFigures()`).
6. Light and dark themes share one layout; only `DkColors` changes. Shadows are off in dark. The app opens in the **light** theme whatever the phone's setting (the dark theme stays in the kit).

---

## 2. Tokens

Implement as `ThemeExtension`s: `DkColors`, `DkTypography`, `DkSpacing`, `DkRadii`,
`DkElevation`, `DkSizes`. Each has `light`/`dark` (where relevant), `copyWith`, `lerp`.
Access via `context.dkColors`, `context.dkText`, etc. (extension on `BuildContext`).

### 2.1 DkColors

| Token | Light | Dark | Usage |
|---|---|---|---|
| bg | `#F4F5F7` | `#0B0D10` | Screen background, bottom bar |
| surface | `#FFFFFF` | `#16191E` | Cards, fields, day switcher, dialog |
| surfaceMuted | `#EEF0F3` | `#22262D` | Icon tiles, disabled fields |
| segmentTrack | `#E9ECF0` | `#22262D` | Segmented control track |
| segmentThumb | `#FFFFFF` | `#343A43` | Selected segment |
| border | `#8F95A0` | `#5F6571` | Field border (default); ≥ 3:1 on `surface` (changed from `#D5DAE1` / `#343A43`, see DECISIONS.md) |
| divider | `#E6E9EE` | `#262B33` | List dividers, card divider, bottom-bar top border |
| textPrimary | `#0F1419` | `#F2F4F7` | Main text, amounts |
| textSecondary | `#4A5260` | `#B4BAC4` | Field labels, trip meta line, body |
| textTertiary | `#5F6673` | `#8B93A0` | Helpers, «комиссия …», metric labels, weekday |
| textDisabled | `#8A919C` | `#5B6370` | Disabled button text |
| iconDisabled | `#C3C8D0` | `#3F4550` | Disabled «next day» chevron |
| accent | `#2450D8` | `#7B9BFF` | Primary button, FAB, «На руки», focus, card segment |
| onAccent | `#FFFFFF` | `#0B0D10` | Text/icon on accent |
| accentSoft | `#E8EEFC` | `#1C2645` | Focus ring, empty-state tile, «+1 день» badge, new-row highlight |
| success | `#127A4B` | `#4CC38A` | (reserved) |
| successSoft | `#E3F4EB` | `#12301F` | (reserved) |
| error | `#C2261F` | `#FF6B61` | Field errors, error icons |
| errorSoft | `#FCE9E8` | `#3A1716` | Error-state / dialog icon tile |
| inverseSurface | `#1A1F26` | `#F2F4F7` | Snackbar |
| onInverse | `#F2F4F7` | `#0F1419` | Snackbar text |
| inverseAccent | `#9DB4FF` | `#2450D8` | Snackbar action |
| inverseError | `#FF8A80` | `#C2261F` | «Нет связи» icon in snackbar |
| inverseSuccess | `#6FD3A0` | `#127A4B` | «Поездка добавлена» icon |
| skeleton | `#E3E6EB` | `#262B33` | DkSkeleton |
| splitNeutral | `#9AA3AF` | `#5B6370` | Cash segment of DkSplitBar |
| disabledFill | `#E1E4E9` | `#2A2F37` | Disabled button background |
| scrim | `#7A0F1419` (0F1419 @ 48%) | `#A3000000` (black @ 64%) | Behind DkDialog |

Contrast: textTertiary ≥ 4.5:1 on `surface` in both themes. Do not put textTertiary on `bg` for essential text.
`border` (field outline) ≥ 3:1 on `surface` in both themes (WCAG 1.4.11).

### 2.2 DkTypography

Font: **Manrope** (Google Fonts, Cyrillic), weights 500/600/700/800.
Bundle the `.ttf` files as assets **inside `packages/design_kit`** (`fonts:` in its pubspec,
referenced as `packages/design_kit/Manrope`). Do not fetch fonts at runtime.
Every style sets `fontFeatures: [FontFeature.tabularFigures()]`.
`height` = lineHeight / fontSize.

| Style | Size / line | Weight | Letter spacing | Used for |
|---|---|---|---|---|
| moneyHero | 44 / 48 | 800 | −0.02em (−0.88) | «На руки» amount; color `accent` |
| moneyHeroSuffix | 32 / 48 | 700 | −0.02em | «₸» after hero amount |
| titleL | 22 / 28 | 800 | −0.01em (−0.22) | Empty/Error state title |
| moneyL | 22 / 28 | 700 | 0 | Amount/commission inside text fields |
| wordmark | 20 / 28 | 800 | −0.02em (−0.4) | «Дневник смен» |
| titleDialog | 20 / 28 | 800 | −0.01em | Dialog title |
| fieldTime | 18 / 24 | 700 | 0 | Time inside time fields |
| titleM | 17 / 24 | 700 | 0 | Day label, section title «Поездки», form app-bar title |
| moneyM | 17 / 24 | 700 | 0 | Summary metric values, payment tile values |
| bodyStrong | 16 / 24 | 700 | 0 | Trip time range, trip amount, button labels |
| body | 16 / 24 | 500 | 0 | Empty/Error message |
| bodyMd | 15 / 22 | 500 | 0 | Dialog message |
| bodyS | 14 / 20 | 500 | 0 | Trip meta («22 мин · Карта»), snackbar text |
| label | 14 / 20 | 600 | 0 | Field labels, «На руки» label |
| captionStrong | 13 / 16 | 600 | 0 | Metric labels, error text, list header count |
| caption | 13 / 16 | 500 | 0 | Helpers, «комиссия 360 ₸», weekday, app-bar subtitle |
| badge | 12 / 24 | 700 | 0 | «+1 день» badge |
| superscript | 11 / 14 | 800 | 0 | «+1» after end time in trip row; color `accent` |

### 2.3 DkSpacing (8-pt grid, 4-pt half steps)

`s2=2, s4=4, s6=6, s8=8, s10=10, s12=12, s14=14, s16=16, s20=20, s24=24, s32=32, s40=40, s48=48, s64=64`

`screenGutter = 16`.

### 2.4 DkRadii

| Token | Value | Usage |
|---|---|---|
| xs | 4 | Split-bar segments, wordmark dot |
| sm | 8 | Skeleton lines, badge |
| segment | 10 | Segmented-control thumb |
| md | 12 | Text fields, icon tiles (40), icon buttons |
| segmentTrack | 14 | Segmented-control track |
| lg | 16 | Cards, day switcher, buttons, snackbar, dialog icon tile |
| xl | 24 | Summary card, dialog, empty/error icon tile (80) |
| pill | 999 | FAB |

### 2.5 DkElevation (light only; dark = none)

| Token | Value |
|---|---|
| e1 | `0 1 2 rgba(15,20,25,0.06)` — day switcher, payment card, trip list card |
| e1Hero | `0 1 2 rgba(15,20,25,0.06)` + `0 2 8 rgba(15,20,25,0.04)` — summary card |
| e2Fab | `0 6 16 rgba(36,80,216,0.28)` — FAB |
| e3 | `0 8 24 rgba(15,20,25,0.24)` — snackbar, dialog |
| thumb | `0 1 3 rgba(15,20,25,0.12)` — selected segment |

Flutter `BoxShadow(offset: Offset(0, y), blurRadius: blur, color: …)`, spread 0.

### 2.6 DkSizes

| Token | Value |
|---|---|
| tapTargetMin | 48 |
| buttonHeight | 56 (primary/secondary), 48 (text) |
| fieldHeight | 56 |
| segmentedHeight | 56 |
| daySwitcherHeight | 56 |
| tripTileMinHeight | 72 |
| iconTile | 40 (radius md), icon 22 |
| stateIconTile | 80 (radius xl), icon 36 |
| dialogIconTile | 56 (radius lg), icon 28 |
| splitBarHeight | 8, gap 3 |
| iconSizes | 24 (nav), 22 (tiles, FAB, buttons), 20 (fields, segments), 16 (inline error, chevron-down) |
| fieldBorder | 1 default, 2 focused/error (reduce horizontal padding 15 → 14 so text does not jump) |
| focusRing | 4 (accentSoft, outside the border) |

### 2.7 Icons

Outline stroke icons, stroke width 2 (2.4 for plus, chevron-down; 2.2 for inline error).
Use `lucide_icons_flutter` (or equivalent outline set). Mapping:

| Meaning | Lucide name |
|---|---|
| previous / next day | `chevron-left` / `chevron-right` |
| date picker hint | `chevron-down` |
| cash | `banknote` |
| card | `credit-card` |
| add | `plus` |
| close | `x` |
| time field | `clock` |
| inline error / dialog | `circle-alert` |
| load error | `cloud-off` |
| no connection | `wifi-off` |
| retry | `rotate-cw` |
| saved | `circle-check` |
| empty state | `route` (road) |

No emoji. No brand logos.

---

## 3. Formatting rules (put in `design_kit/lib/src/format/` or `core/` — one place only)

- **Money:** integer tenge, groups of 3 separated by **U+202F** (narrow no-break space), then U+202F, then `₸`.
  `3315 → "3 315 ₸"`, `585 → "585 ₸"`. Negative commission in summary uses **U+2212** minus: `"−585 ₸"`.
  Never use `NumberFormat` with locale default spaces (U+00A0) — tests must assert U+202F.
- **Hero:** number and `₸` are separate text spans (`moneyHero` + `moneyHeroSuffix`), joined by U+202F.
- **Time:** `HH:mm`, 24h. Range uses en dash with spaces: `08:10 – 08:32`.
- **Duration:** `< 60` → `"22 мин"`; `≥ 60` → `"1 ч 5 мин"` / `"2 ч"`.
- **Dates (ru):** `"1 октября 2026"` (genitive month). Weekday capitalised: `"Четверг"`.
- **Relative label:** if date == today → title `"Сегодня"`, subtitle = full date; yesterday → `"Вчера"` + date;
  otherwise title = full date, subtitle = weekday.
- **Trip count plural:** 1 поездка, 2–4 поездки, 5+ поездок (Russian rules incl. 11–14 → поездок).
- **Split percentages:** rounded, must sum to 100 (largest-remainder). Hidden when revenue = 0.
- **Cross-midnight end:** `"23:50 – 00:20"` + superscript `"+1"` (accent).

---

## 4. Components (`packages/design_kit/lib/src/components/`)

All components read tokens only. No hard-coded colors/sizes in `apps/mobile`.

### DkButton
`DkButton({required String label, VoidCallback? onPressed, DkButtonVariant variant = primary, bool isLoading = false, IconData? icon, bool expand = false})`
- primary: bg `accent`, fg `onAccent`. secondary: bg `accentSoft`, fg `accent`. text: transparent, fg `accent`, height 48, radius md.
- height 56, radius lg, horizontal padding 24 (20 on the icon side), icon 22 + gap 8, style `bodyStrong`.
- disabled (`onPressed == null`): bg `disabledFill`, fg `textDisabled` (text variant: fg only).
- loading: spinner 20 (stroke 2.6, same fg) + gap 10 + label (`"Сохраняем…"`), not tappable, `Semantics(busy)`.

### DkFab
`DkFab({required String label, required IconData icon, required VoidCallback onPressed})`
Height 56, radius pill, padding 0 24 0 20, gap 8, icon 22, `bodyStrong`, bg `accent`, shadow `e2Fab` (none in dark).
Position: right 16, bottom = safe-area bottom + 16.

### DkCard
`DkCard({required Widget child, EdgeInsets padding = 16, double radius = lg, bool hero = false})`
bg `surface`, shadow `e1` (`e1Hero` when hero). Dark: no shadow.

### DkSummaryCard (composite; uses DkCard hero, padding 20, radius xl, gap 16)
- «На руки» (`label`, textSecondary) → gap 4 → hero amount (`moneyHero` accent + suffix).
- divider 1px `divider`.
- 3-column grid, gap 12: `DkSummaryTile` Выручка / Комиссия / Поездок.

### DkSummaryTile
`DkSummaryTile({required String label, required String value, IconData? icon, String? hint})`
- Without icon: label `captionStrong` textTertiary → gap 2 → value `moneyM`.
- With icon (payment tile): icon tile 40 (surfaceMuted, radius md, icon 22 textPrimary) → gap 12 → column(label `"Наличные · 38%"` captionStrong textTertiary, value `moneyM`).
- The label is **one line**: in a narrow tile it scales down to fit instead of wrapping the share onto a second line.

### DkSplitBar
`DkSplitBar({required int cash, required int card})` — height 8, gap 3, each segment radius xs,
cash = `splitNeutral` (left), card = `accent` (right), flex = amounts. Semantics label `"Наличные 38%, карта 62%"`.
Payment card = DkCard(padding 16, gap 14): Row of two payment DkSummaryTiles (grid 2 cols, gap 12) + DkSplitBar.

### DkTripTile (read-only, no onTap)
`DkTripTile({required String timeRange, required bool endsNextDay, required String meta, required String amount, required String commission, required PaymentMethod method, bool highlighted = false})`
- min height 72, padding 12/16, gap 12.
- icon tile 40 (surfaceMuted; `surface` when highlighted) with banknote / credit-card.
- center: timeRange `bodyStrong` (+ `superscript` "+1" if endsNextDay) / meta `bodyS` textSecondary (`"22 мин · Карта"`), one line (scales down to fit, never wraps).
- right, end-aligned: amount `bodyStrong` / `"комиссия 360 ₸"` `caption` textTertiary.
- highlighted: row bg `accentSoft` for ~2 s after the trip is created, then fades.
- In a list: one DkCard(padding 0, clip), dividers 1px `divider` inset left 68.
- List header above the card: «Поездки» `titleM` + right `"2 поездки · 37 мин"` `captionStrong` textTertiary (one line, scales down to fit) + optional `action` (the sort `DkIconButton`), padding 0 4, gap 8 to card.

### DkDaySwitcher
`DkDaySwitcher({required DateTime date, required DateTime today, required VoidCallback onPrev, VoidCallback? onNext, required VoidCallback onPickDate})`
- height 56, bg `surface`, radius lg, padding 4, shadow e1.
- left/right: 48×48 icon buttons (radius md, chevron 24). Next disabled (color `iconDisabled`) when date == today.
- center button (flex): title `titleM` + chevron-down 16 (textTertiary) / subtitle `caption` textTertiary (rules §3).
- Semantics: «Предыдущий день», «Следующий день», «Выбрать дату, 1 октября 2026».
- Date picker: `showDkDatePicker` (DkPickerSheet, iOS-style wheel on every platform), `lastDate: today`, header shortcut «Сегодня».

### DkTextField
`DkTextField({required String label, required TextEditingController controller, String? helper, String? errorText, Widget? prefixIcon, String? suffix, Widget? trailing, TextStyle? style, TextInputType? keyboardType, bool enabled = true})`
- label `label` style (textSecondary; `accent` when focused; `error` when error) → gap 8 → field → gap 6 → helper `caption` textTertiary or error row.
- field: height 56, radius md, bg `surface`, border 1 `border`, padding h 15.
- focused: border 2 `accent` + outer ring 4 `accentSoft`, padding h 14.
- error: border 2 `error`, prefix icon `error` (as in mockup 08); error row = icon `circle-alert` 16 + gap 6 + text `captionStrong` error. Semantics: `aria-invalid` equivalent, error read after label.
- disabled: bg `surfaceMuted`, border `divider`, text textSecondary.
- variants: **time** (prefix clock 20 textTertiary, gap 10, style `fieldTime`, opens `showDkTimePicker`, a DkPickerSheet wheel, 24 h), **money** (style `moneyL`, suffix `"₸"` 20/700 textTertiary, numeric keyboard, groups digits with U+202F while typing).
- `trailing` slot used for `DkBadge('+1 день')`.

### DkBadge
height 24, radius sm, padding h 8, bg `accentSoft`, text `badge` accent.

### DkSegmentedControl<T>
`DkSegmentedControl<T>({required List<DkSegment<T>> segments, required T selected, required ValueChanged<T> onChanged})`
- height 56, track `segmentTrack` radius 14 padding 4, gap 4.
- thumb: `segmentThumb`, radius 10, shadow `thumb` (light only), label `bodyStrong` textPrimary.
- unselected: transparent, 16/600 textSecondary. Each segment = icon 20 + gap 8 + label.
- Semantics: radio group; animate thumb 200 ms easeOut.

### DkSnackbar
`showDkSnackbar(context, {required String message, DkSnackTone tone, String? actionLabel, VoidCallback? onAction})`
- error/info: full width (left/right 16), bg `inverseSurface`, radius lg, padding 8 8 8 16, gap 12, shadow e3; icon 22 (`wifi-off` inverseError) + text `bodyS` onInverse + text button (h48, 15/700 inverseAccent).
  Sits 12 above the form bottom bar. Stays until success. In the form it is part of the layout (a `DkSnackbarView` in a `Stack` above the bottom bar), not an overlay entry, so it moves with the bar when the keyboard opens or closes.
- success: compact, height 56, padding 0 16 0 14, gap 8, icon `circle-check` 22 inverseSuccess, text 14/600 onInverse; placed bottom-left (left 16, bottom safe+16) **beside the FAB, never over it**; auto-dismiss 3 s.

### DkDialog
`showDkDialog(context, {required IconData icon, required String title, required String message, required String primaryLabel, required VoidCallback onPrimary, String? secondaryLabel, VoidCallback? onSecondary})`
scrim `scrim`; card `surface` radius xl, padding 24, gap 20, margin h 24, shadow e3;
max width 400; icon tile 56 (errorSoft / error, icon 28) **centred** → title `titleDialog` + gap 8 + message `bodyMd` textSecondary, both **centred** → buttons stacked full-width, gap 8: primary DkButton, secondary DkButton.secondary.

### DkPickerSheet
`showDkTimePicker(context, {required int hour, required int minute, String title, String doneLabel})` → `({int hour, int minute})?`
`showDkDatePicker(context, {required DateTime initialDate, required DateTime firstDate, required DateTime lastDate, String title, String doneLabel, String? todayLabel})` → `DateTime?`
- Modal bottom sheet, bg `surface`, top radius xl, scrim `scrim`; padding 8 16 8 16 + safe area. Not capped at 9/16 of the screen: on a short screen or with large text the content scrolls.
- Handle 40×4 `border` radius pill → header row (min 48): title `titleM` textPrimary + optional text button shortcut (date: «Сегодня» selects `lastDate`) → `CupertinoDatePicker` wheel 216 high (time: 24 h; date: min/max dates), text `titleM` w500 textPrimary → gap 8 → DkButton primary expand «Готово».
- The same iOS-style wheel on Android and iOS. Dismissing the sheet (swipe or scrim) = cancel (null).

### DkOptionsSheet
`showDkOptionsSheet<T>(context, {required String title, required List<DkOption<T>> options, required T selected})` → `T?`
Same sheet as DkPickerSheet (handle, title `titleM` padding 12 16); rows min 56, padding 0 16: label `body` textPrimary + `check` 22 `accent` on the selected row. Tap = choose and close. Rows are a mutually exclusive group for screen readers.

### DkIconButton
`DkIconButton({required IconData icon, required String label, required VoidCallback onPressed, bool active = false})`
48×48, transparent, radius md, icon 22 `textPrimary` (`accent` when `active`). `label` is the spoken name.

### DkTodayButton
`DkTodayButton({required VoidCallback onPressed, String label = 'Сегодня'})`
Pill bg `accentSoft`, padding 6 12, gap 6: icon `calendar-check` 16 + label `captionStrong` accent; tap area 48 high. Placed in `DkWordmark(trailing: …)`.

### DkEmptyState / DkErrorState
`DkEmptyState({required String title, String? message, String? actionLabel, VoidCallback? onAction})`
`DkErrorState({required String title, String? message, required VoidCallback onRetry, bool isRetrying = false})`
Centered column, padding 0 16 64, gap 24: icon tile 80 radius xl (Empty: accentSoft/accent `route`; Error: errorSoft/error `cloud-off`, icon 36) → column(title `titleL`, gap 8, message `body` textSecondary, centered) → DkButton.primary (auto width; Empty: icon plus; Error: icon rotate-cw). Error state is a live region.

### DkSkeleton
`DkSkeleton.line({double width, double height})`, `.box({double size, double radius})`,
`DkSkeleton.summaryCard()`, `.paymentCard()`, `.tripTile()`.
Color `skeleton`; pulse opacity 1 → 0.55 → 1, 1.4 s ease-in-out; disabled when `MediaQuery.disableAnimations`.
Composite skeletons replicate the real layout 1:1 (same paddings, radii, tile sizes).
Line sizes used: label 72×16 r8, hero 196×44 r12, metric 56–64×12 r6 + 64–80×20 r8, trip 112×16 + 88×12, amount 68×16 + 96×12, bar h8 r4.

---

## 5. Screens (variant A)

Frame 390×844. Content respects `SafeArea` (top inset in mockup = 54, bottom = 34). Side padding 16.

### 5.1 Day — `01_day_light` / `02_day_dark`
Column, gap 16, scrollable (`RefreshIndicator` for pull-to-refresh), bottom padding so the last tile clears the FAB:
1. Header: wordmark row (height 48): 12×12 accent square radius 4, gap 10, «Дневник смен» `wordmark`; on the right, `DkTodayButton` «Сегодня» while another day is shown (jumps to today).
2. gap 8 → DkDaySwitcher.
3. DkSummaryCard.
4. Payment card (DkSummaryTile ×2 + DkSplitBar).
5. Trips header + list card (DkTripTile ×N).
FAB «+ Поездка» (DkFab, icon plus).
Sample data 1 октября 2026: На руки 3 315 ₸; Выручка 3 900 ₸; Комиссия −585 ₸; Поездок 2;
Наличные · 38% 1 500 ₸; Карта · 62% 2 400 ₸; header «2 поездки · 37 мин»;
trips «08:10 – 08:32 / 22 мин · Карта / 2 400 ₸ / комиссия 360 ₸», «09:05 – 09:20 / 15 мин · Наличные / 1 500 ₸ / комиссия 225 ₸».

### 5.2 Day — empty (`03_day_empty`)
Header + switcher («Сегодня» / «6 октября 2026», next disabled), then DkEmptyState fills the rest:
title «За этот день поездок нет», message «Добавьте поездку — выручка, комиссия и сумма на руки посчитаются сами.», button «Добавить поездку». No FAB.

### 5.3 Day — loading (`04_day_loading`)
Header + real switcher, then DkSkeleton.summaryCard, .paymentCard, list header skeleton (88×18), 3× tripTile. FAB visible.
On refresh with existing data: keep data, show the refresh indicator only (no skeleton).

### 5.4 Day — error (`05_day_error`)
Header + switcher, DkErrorState: «Не удалось загрузить данные» / «Проверьте интернет и попробуйте ещё раз. Сохранённые поездки никуда не пропадут.» / «Повторить». No FAB.
If data was already shown and a refresh fails: keep data, show error DkSnackbar instead.

### 5.5 Day — trip added (`06_day_trip_added`)
After a successful save the form closes, the day of the trip's **start** is shown, the new DkTripTile is `highlighted`, success snackbar «Поездка добавлена» bottom-left next to the FAB. The list scrolls the new row to the middle of the screen (`Scrollable.ensureVisible`, alignment 0.5, `DkMotion.reveal` 300 ms; instant with reduced motion), so it is seen in a long list.

**Sorting.** The «Поездки» header has a sort `DkIconButton` (`arrow-up-down`; `accent` when not the default; spoken «Сортировка: сначала ранние»). It opens a `DkOptionsSheet` «Сортировка»: «Сначала ранние» (default), «Сначала поздние», «Сначала дорогие», «Сначала дешёвые». Equal amounts keep start order. The choice holds for every day until the app restarts.

### 5.6 Add trip — form (`07_add_trip`)
**Full-screen modal route** (`fullscreenDialog: true`), not a bottom sheet:
5 inputs + keyboard ≈ full height anyway; Save stays pinned above the keyboard; no accidental swipe-dismiss.
- App bar height 56, padding h 8: close icon button 48 (`x`, «Закрыть»), centered title «Новая поездка» `titleM` + subtitle date `caption`, right spacer 48.
- Form padding 8 16, gap 20:
  1. Row (2 cols, gap 12): time fields «Начало», «Окончание»; under the row (gap 6) helper «Длительность: 22 мин».
  2. «Сумма» money field, helper «Сколько заплатил пассажир».
  3. «Комиссия» money field, helper «На руки с поездки: 2 040 ₸».
  4. «Способ оплаты» label + DkSegmentedControl (Наличные / Карта).
- Bottom bar: bg `bg`, top border 1 `divider`, padding 12 16 (safe-area + 8); DkButton «Сохранить» full width.
- If the user closes with unsaved input → confirm discard (standard dialog).

### 5.7 Add trip — validation (`08_add_trip_errors`)
Client validation mirrors the server. Show errors after a field loses focus or after Save is pressed; while any error exists Save is disabled.
- end ≤ start (see midnight rule) → under the time row: «Окончание должно быть позже начала»
- amount ≤ 0 → «Сумма должна быть больше 0»
- commission > amount → «Комиссия не может быть больше суммы»
- commission < 0 → «Комиссия не может быть отрицательной»
- empty field → «Заполните поле»
Server 422 `{error:{field}}` maps to the same field + same UI; unknown field → error DkSnackbar.

### 5.8 Add trip — saving (`09_add_trip_saving`)
Inputs disabled (surfaceMuted / divider / textSecondary), segmented disabled, Save = loading «Сохраняем…».

### 5.9 Add trip — no connection (`10_add_trip_offline`)
Form editable again, Save enabled, error DkSnackbar «Нет связи. Повторим отправку — поездка не задвоится.» + «Повторить».
The app **retries automatically** (backoff 2 s, 4 s, 8 s, then every 30 s while the form is open) **with the same trip id**; «Повторить» retries immediately. Editing any field after a failed send generates a **new** id.

### 5.10 Add trip — cross midnight (`11_add_trip_midnight`)
**Rule:** if end time ≤ start time on the clock, end = next day. Show DkBadge «+1 день» in the end field and helper
«Окончание 1 октября · 30 мин. Поездка попадёт в 30 сентября — день начала.»
Error «Окончание должно быть позже начала» only if the resulting duration is 0 or > 12 h (e.g. 09:20 → 09:05).
Full ISO datetimes with offset are sent to the server; the server still enforces end > start.

### 5.11 Add trip — conflict 409 (`12_add_trip_conflict_409`)
DkDialog over the form: icon circle-alert, title «Эта поездка уже сохранена с другими данными»,
message «Первая отправка дошла до сервера, а потом поля изменились. Сохранено: 08:10 – 08:32 · 2 400 ₸ · Карта.»
(values from the 409 response body), primary «Оставить сохранённую» (close form, refresh day),
secondary «Сохранить как новую поездку» (new id, resubmit).

---

## 6. Copy (all UI text, Russian)

| Key | Text |
|---|---|
| appTitle | Дневник смен |
| netLabel | На руки |
| revenue / commission / trips | Выручка / Комиссия / Поездок |
| cash / card | Наличные / Карта |
| tripsTitle | Поездки |
| commissionLine | комиссия {amount} |
| today / yesterday | Сегодня / Вчера |
| prevDay / nextDay / pickDate | Предыдущий день / Следующий день / Выбрать дату |
| addTripFab | Поездка |
| emptyTitle | За этот день поездок нет |
| emptyMessage | Добавьте поездку — выручка, комиссия и сумма на руки посчитаются сами. |
| emptyAction | Добавить поездку |
| errorTitle | Не удалось загрузить данные |
| errorMessage | Проверьте интернет и попробуйте ещё раз. Сохранённые поездки никуда не пропадут. |
| retry | Повторить |
| formTitle | Новая поездка |
| start / end / amount / commission / payment | Начало / Окончание / Сумма / Комиссия / Способ оплаты |
| durationHelper | Длительность: {duration} |
| amountHelper | Сколько заплатил пассажир |
| netHelper | На руки с поездки: {amount} |
| nextDayBadge | +1 день |
| save / saving | Сохранить / Сохраняем… |
| close | Закрыть |
| errEndBeforeStart | Окончание должно быть позже начала |
| errAmount | Сумма должна быть больше 0 |
| errCommissionGtAmount | Комиссия не может быть больше суммы |
| errCommissionNegative | Комиссия не может быть отрицательной |
| errRequired | Заполните поле |
| offline | Нет связи. Повторим отправку — поездка не задвоится. |
| saved | Поездка добавлена |
| conflictTitle | Эта поездка уже сохранена с другими данными |
| conflictKeep / conflictNew | Оставить сохранённую / Сохранить как новую поездку |

Keep copy in one file (`core/l10n/strings_ru.dart` or ARB). No English strings in UI.

---

## 7. Acceptance checklist (screenshots must match the mockups)

- [x] Example app (`packages/design_kit/example`) shows every component in every state, light + dark. *(`example/test`: every component type, both themes, no overflow at 360 dp)*
- [x] Golden tests for: DkSummaryCard, DkTripTile (card, cash, +1, highlighted), DkTextField (default/focused/error), DkButton matrix, DkDaySwitcher (date / Сегодня), Day screen light + dark with sample data. *(`packages/design_kit/test/goldens`, `apps/mobile/test/screens/goldens`)*
- [x] `grep -R "Color(0x" apps/mobile` → 0 results; no literal sizes for spacing/radii in `apps/mobile`. *(CI step also rejects `Colors.` and `TextStyle(`)*
- [x] Money formatting tests assert U+202F and U+2212. *(`dk_money_test.dart`)*
- [x] All tap targets ≥ 48; Semantics labels as listed. *(`apps/mobile/test/screens/accessibility_test.dart`, every state, light + dark)*
- [x] Text scale 1.3: no clipping on Day and Add trip screens. *(`layout_matrix_test.dart`: 390×844 and 360×780, 1.0 and 1.3, real fonts; no overflow, no truncated text)*
