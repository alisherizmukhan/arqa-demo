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
| routeLine | `#2450D8` | `#7B9BFF` | Trip route on the map (= accent), §9 |
| routeCasing | `#FFFFFF` | `#0B0D10` | Outline under the route line, §9 |
| markerA | `#0F1419` | `#F2F4F7` | Start marker «A» (= textPrimary), §9 |
| markerB | `#2450D8` | `#7B9BFF` | End marker «B» (= accent), §9 |
| markerRing | `#FFFFFF` | `#FFFFFF` | Ring around the place markers, §9 |
| routeMuted | `#9AA3AF` | `#5B6370` | The day map's other routes while one is selected, §9.5 |

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

---

## 8. New screens (accounts, menu, withdrawals, admin)

### 8.0 New kit components
- DkIconButton: 48×48, radius md, icon 24, transparent; used in headers.
- DkListGroup + DkListRow: DkCard(padding 0, clip) with rows min 56, padding 0 16, gap 12: leading icon tile 40 (surfaceMuted, icon 22), title bodyStrong (or titleM-weight 600 16/24), optional subtitle caption textTertiary, trailing (chevron-right 20 textTertiary | value | control). Dividers 1px divider inset 68. Destructive row: title + icon in `error`.
- DkStatusChip: height 24, radius sm, padding h 8, gap 4, icon 14 + text badge style.
  pending: bg surfaceMuted, fg textSecondary, icon clock; paid: bg successSoft, fg success, icon circle-check; rejected: bg errorSoft, fg error, icon circle-x. Always icon + text.
- DkPasswordField: DkTextField + trailing DkIconButton eye / eye-off («Показать пароль» / «Скрыть пароль»).
- DkLanguageSwitch: DkSegmentedControl with two segments «Русский» / «Қазақша» (no icons). Labels are always in their own language, never translated.
- DkFilterChips: horizontal scroll row of chips height 40 (tap area 48), radius pill, padding h 16; selected bg accent fg onAccent; unselected bg surface, border 1 border, fg textPrimary; label 14/600.

### 8.1 Login
- bg `bg`, SafeArea, padding 16. Top-right: DkLanguageSwitch (width 200, height **56** — approved: at 48 the segments would be 40, below the 48 dp tap target).
- Centered block (max width 360): wordmark (accent square 16 + «Дневник смен» wordmark style), gap 32, title «Вход» titleL, gap 24, fields «Логин» (DkTextField, autofill username), gap 16 «Пароль» (DkPasswordField, autofill password), gap 24, DkButton primary expand «Войти» (loading «Входим…»).
- Error: under the password field, error row «Неверный логин или пароль». Rate-limit: «Слишком много попыток. Попробуйте через 15 минут.» Offline: error snackbar «Нет связи. Проверьте интернет.»
- Keyboard: Enter on login → focus password; Enter on password → submit.

### 8.2 Day screen header change (only change to existing screens)
- Wordmark row gets a trailing DkIconButton (icon `circle-user-round`, Semantics «Меню»). Opens Menu (8.3). Nothing else changes.

### 8.3 Menu («Меню»)
- Pushed page. App bar like Add trip but with back arrow (`chevron-left`, «Назад») instead of close; title «Меню».
- Profile card (DkCard, padding 16, row gap 12): icon tile 40 with `user-round`, column: display_name titleM, «@user_1 · Водитель» caption textTertiary (admin: «Администратор»).
- gap 16, DkListGroup:
  1. «Вывод средств» — icon `wallet`, subtitle «Доступно 1 815 ₸» (from /balance), chevron → 8.4. (Drivers only.)
  2. «Язык» — icon `languages`, trailing nothing; below the row inside the group: DkLanguageSwitch full width (padding 0 16 16).
- gap 16, DkListGroup: «Выйти» destructive row (icon `log-out`). Tap → DkDialog: icon log-out (errorSoft/error), title «Выйти из аккаунта?», message «Чтобы снова увидеть поездки, нужно будет войти по логину и паролю.», primary «Выйти», secondary «Отмена».
- Footer caption textTertiary centered: app version.

### 8.4 Withdraw («Вывод средств»)
- Pushed page, back arrow, title «Вывод средств». Scrollable, padding 16, gap 16; bottom bar like Add trip with DkButton «Вывести».
- Balance card = DkCard hero (radius xl, padding 20, gap 16): label «Доступно к выводу» → moneyHero accent amount; divider; 3-col DkSummaryTile grid: «Безнал» (Σ card), «Комиссия» (−Σ commission), «Выведено» (−Σ pending+paid).
  Helper under the card (caption textTertiary): «Наличные остаются у вас, поэтому комиссия за них тоже списывается с безнала.»
- Amount: DkTextField money «Сумма вывода», helper «Не больше 1 815 ₸». Trailing text button «Всё» (fills the available amount).
- History: DkListHeader «История» + DkTripTile-like rows in a DkCard: icon tile `wallet` / title amount bodyStrong / subtitle date «5 октября 2026, 14:20» caption / trailing DkStatusChip («В обработке» / «Выплачено» / «Отклонено»; rejected shows reason as second subtitle line).
- States:
  - loading: skeleton of balance card + 3 history rows;
  - empty history: small text «Заявок на вывод пока не было.» in the history card;
  - balance ≤ 0: amount field disabled, button disabled, info row (icon `info`, textSecondary) «Сейчас нечего выводить.»;
  - validation: «Сумма больше доступной», «Сумма должна быть больше 0»;
  - saving: button loading «Отправляем…»;
  - offline: error snackbar «Нет связи. Повторим запрос — деньги не уйдут дважды.» + «Повторить»;
  - success: back to the top, new row highlighted (accentSoft 2 s), success snackbar «Заявка на вывод создана»;
  - 409: DkDialog «Эта заявка уже отправлена с другой суммой», primary «Понятно» (refresh history).

### 8.5 Session ended
- Any 401 → Login with error snackbar «Сессия завершена. Войдите снова.»

### 8.6 Admin («Админка»)
- Day-screen layout reused. Header: wordmark + caption «Администратор» + DkIconButton menu (Menu without «Вывод средств»).
- Under the header: DkSegmentedControl with 3 segments: «Поездки» / «Выводы» / «Водители».
- Поездки: DkFilterChips «Все водители», «Водитель 1», «Водитель 2» (from /admin/users) → DkDaySwitcher → summary card + payment card + trip list for the selection. In «Все водители» each trip row keeps its meta line «22 мин · Карта» and gets the driver's name on its own **third line** (`caption`, textTertiary, one line, ellipsis) — same size in every row, never shrunk to fit (`DkTripTile(driver: …)`). No FAB (admin does not create trips).
- Выводы: DkFilterChips «В обработке», «Все»; list rows (`DkWithdrawalTile(prominent: true)`): title = amount (`moneyM`, `DkMoneyText`), subtitle = «Водитель 2 · 9 окт., 22:34» (`caption`, one line), status chip on the right; no reject reason in the admin list, so every row's content block has the same height (and every row with buttons too) at 360 and 390 dp, text 1.0 — tested; pending rows have two buttons under the row content: DkButton secondary «Отклонить» and primary «Выплатить» (each 48 high, side by side). Reject opens a dialog with a text field «Причина» (required). Approve → no dialog, button loading then row updates; success snackbar «Отмечено как выплачено».
- Водители: DkListGroup rows: display name, «@user_1», trailing balance moneyM; row tap → bottom sheet with actions: «Заблокировать» / «Разблокировать» (is_active), «Сбросить все сессии» (confirm dialog «Водитель выйдет на всех устройствах»).
- Empty / error / loading states reuse DkEmptyState, DkErrorState, DkSkeleton.

### 8.7 Copy additions (ru; kk goes to app_kk.arb)
login «Логин», password «Пароль», loginTitle «Вход», signIn «Войти», signingIn «Входим…», showPassword «Показать пароль», hidePassword «Скрыть пароль», errInvalidCredentials «Неверный логин или пароль», errRateLimited «Слишком много попыток. Попробуйте через 15 минут.», sessionEnded «Сессия завершена. Войдите снова.», menu «Меню», back «Назад», roleDriver «Водитель», roleAdmin «Администратор», withdraw «Вывод средств», available «Доступно {amount}», language «Язык», logout «Выйти», logoutTitle «Выйти из аккаунта?», logoutMessage «Чтобы снова увидеть поездки, нужно будет войти по логину и паролю.», cancel «Отмена», availableToWithdraw «Доступно к выводу», cardTotal «Безнал», withdrawn «Выведено», cashNote «Наличные остаются у вас, поэтому комиссия за них тоже списывается с безнала.», withdrawAmount «Сумма вывода», maxHint «Не больше {amount}», all «Всё», history «История», noWithdrawals «Заявок на вывод пока не было.», nothingToWithdraw «Сейчас нечего выводить.», errInsufficient «Сумма больше доступной», withdrawButton «Вывести», sending «Отправляем…», withdrawOffline «Нет связи. Повторим запрос — деньги не уйдут дважды.», withdrawCreated «Заявка на вывод создана», withdrawConflict «Эта заявка уже отправлена с другой суммой», ok «Понятно», statusPending «В обработке», statusPaid «Выплачено», statusRejected «Отклонено», admin «Админка», tabTrips «Поездки», tabWithdrawals «Выводы», tabDrivers «Водители», allDrivers «Все водители», approve «Выплатить», reject «Отклонить», rejectReason «Причина», markedPaid «Отмечено как выплачено», block «Заблокировать», unblock «Разблокировать», revokeSessions «Сбросить все сессии», revokeSessionsMessage «Водитель выйдет на всех устройствах».

### 8.8 Kit implementation (stage 4)

Components live in `packages/design_kit/lib/src/components/dk_accounts.dart` unless noted. They have **no texts of their own** — every label is a parameter — so the app can translate them (stage 5). Showcase: `packages/design_kit/example`, «Аккаунты» tab and `example/test/accounts_screens_test.dart` (renders every screen state, light + dark).

| §8.0 item | Kit API |
|---|---|
| DkIconButton | `DkIconButton(icon, label, onPressed, active)` in `dk_chrome.dart`; icon 24 (`iconNav`); `active` draws the icon in `accent` (the sort button). |
| DkListGroup + DkListRow | `DkListGroup(children)` inserts the inset-68 dividers; `DkListAttachment(child)` sits under the row above it without a divider (the language switch under «Язык»). `DkListRow(title, icon, subtitle, trailing, onTap, destructive)` — a chevron when tappable and no trailing. |
| DkStatusChip | `DkStatusChip(kind: DkStatusKind.pending/paid/rejected, label)`. |
| Money in any text | Every amount is built by `DkMoney.format` (U+202F before ₸ and between groups, U+2212 minus) and drawn by `DkMoneyText` / `DkGroupedText`, which widen the gap; a plain `Text` draws U+202F too narrow. Kit texts that can carry an amount (list rows, dialog title and message, snackbars, sheet titles, info line, withdrawal rows) render through `DkGroupedText`. `example/test/accounts_screens_test.dart` fails on any rendered «₸» without U+202F before it, a hyphen minus, or a narrow gap. |
| DkPasswordField | `DkPasswordField(label, controller, showLabel, hideLabel, …)`; `DkTextField` gained `obscureText`, `autofillHints`, `onSubmitted`, and its `trailing` is now a separate semantics node (otherwise the eye button merged into the field and was unreachable for screen readers). |
| DkLanguageSwitch | `DkLanguageSwitch(languages: [(code, name)], selected, onChanged)`. **Approved deviation:** always 56 high, also on the login screen — a 48-high track (§8.1 "compact") leaves 40-high segments, below the 48 dp tap target of §1. The login switch keeps width 200. |
| DkFilterChips | `DkFilterChips<T>(options: [(value, label)], selected, onChanged)`. |

Also added for §8.3–8.6:

- `DkModalAppBar(leadingIcon: DkIcons.previous, closeLabel: …)` — the back-arrow app bar of a pushed page.
- `DkWordmark(caption: …)` — «Администратор» under the wordmark (§8.6); `trailing` takes the header buttons.
- `DkProfileCard(name, caption)` — §8.3 profile card.
- `DkBalanceCard(label, amount, tiles)` — §8.4 balance card (summary-card layout; tiles marked `deduction` show `−`).
- `DkWithdrawalTile(amount, subtitle, status, prominent, note, actions, highlighted)` and `DkDecisionButtons(…)` — §8.4 history rows and §8.6 rows with «Отклонить» / «Выплатить» (`DkButton(compact: true)` = 48 high).
- `DkInfoRow(text)` — «Сейчас нечего выводить.»
- `showDkActionSheet(title, subtitle, actions)` / `DkActionSheet` — §8.6 driver actions.
- `DkDialogView` / `showDkDialog`: `content` slot (the «Причина» field), `primaryEnabled`, `primaryLoading`.

### 8.9 Languages (stage 5)

- **The kit has no texts at all.** The Russian defaults of the older components became required parameters: `DkSummaryCard` (4 labels), `DkPaymentCard` / `DkSplitBar` (cash / card), `DkWordmark.title`, `DkTodayButton.label`, `DkModalAppBar.closeLabel`, `DkErrorState.retryLabel`, `DkTimeField.emptyValueLabel`, `DkTripTile.nextDayLabel`, `showDkTimePicker` / `showDkDatePicker` (`title`, `doneLabel`). `DkPaymentMethod.label` is gone.
- **`DkDaySwitcher` takes formatted texts**: `title`, `subtitle`, `pickLabel` (spoken), `prevLabel`, `nextLabel`; `onNext: null` disables next (today). The app formats Сегодня / Вчера / the date in the active language.
- **`DkFormat` keeps only language-neutral helpers** (`clock`, `timeRange`, `splitPercent`). Dates, durations and plurals are formatted by the app (`AppFormat` on `AppLocalizations`, `intl` + ICU plurals). The showcase has its own Russian helpers (`example/lib/ru.dart`).
- **`DkMoneySemantics(label)`** above the screens tells `DkMoneyText` how to speak an amount («3 315 тенге» / «3 315 теңге»); without it a screen reader reads the visible text.
- Money looks the same in every language (`DkMoney.format`).
- CI fails on a Cyrillic literal in `apps/mobile/lib` or `packages/design_kit/lib` outside the generated localizations. Copy and the review list: `docs/L10N.md`.

## 9. Maps: trip places and routes

The driver may set where a trip started (A) and ended (B) on a map; the server builds the road route once (docs/MAPS.md). Every new screen follows §10.

### 9.0 Tokens

| Token | Light | Dark | Use |
|---|---|---|---|
| routeLine | `#2450D8` (= accent) | `#7B9BFF` (= accent) | The route line |
| routeCasing | `#FFFFFF` | `#0B0D10` | Outline under the route line |
| markerA | `#0F1419` (= textPrimary) | `#F2F4F7` (= textPrimary) | Marker «A»; its letter is `surface` |
| markerB | `#2450D8` (= accent) | `#7B9BFF` (= accent) | Marker «B»; its letter is `onAccent` |
| markerRing | `#FFFFFF` | `#FFFFFF` | 2 dp ring around both markers |
| routeMuted | `#9AA3AF` | `#5B6370` | The day map's other routes while one is selected |

**Tiles follow the theme.** The tile URLs and the attribution come from the build (`--dart-define` `TILE_URL_LIGHT`, `TILE_URL_DARK`, `TILE_ATTRIBUTION`), never literals in widgets. The demo uses OpenStreetMap tiles for both themes. In the dark theme they are drawn through flutter_map's `darkModeTileBuilder` (inverted, hue rotated), so the map is not a white block. A real dark style (`TILE_URL_DARK` ≠ `TILE_URL_LIGHT`) is shown as it is. The filter touches only the tiles: route, markers and attribution are drawn above them in theme colors.

### 9.1 Components

- **DkMapView** wraps flutter_map.
  - Radius `lg`, clipped. The full-screen picker has no radius.
  - The attribution is always visible, compact and on one line (stage 3 review):
    - a chip at the bottom right, 11/14 textSecondary on `surface` at 90 %, radius `xs`;
    - «© OpenStreetMap», plus « · © openrouteservice.org by HeiGIT» (ORS's requested wording) while a route built by ORS is drawn (`extraAttribution`);
    - it never wraps: a long credit scales down; one line at 360 dp and text ×1.3 (tested);
    - tapping it (a 48 dp area) opens «Данные карты» with the full credits and licence links, selectable (`showDkMapCredits`). See MAPS.md «Attribution».
  - Rotation is off. The camera fits the route with padding 48 (closest zoom 16).
  - On a small map the padding shrinks to a quarter of the shorter side.
  - The bottom padding has extra room (up to 32) so the attribution never covers a marker.
  - `surfaceMuted` shows behind the tiles. If tiles fail to load, the map is a grey area with the attribution, and the screen still works.
- **DkRouteLayer:** a 5 dp line in `routeLine` over an 8 dp `routeCasing`.
  - Dashed 6/6 when `route_status = straight`.
  - On the day map, tapping a route opens its trip.
- **DkPlaceMarker:** a 32 dp circle with a 2 dp `markerRing` and the letter «A» / «B» (13/800).
  - A is `markerA`, B is `markerB`.
  - Semantics «Начало поездки» / «Конец поездки». On the map, flutter_map's moving layer does not expose them; the place fields under the map carry the same names.
  - The letter does not scale with the text size.
- **DkPlaceField:** a row like DkListRow, **64 high**, padding 0 16, gap 12. From start to end:
  - DkPlaceMarker (A/B) in the 40 slot;
  - the label «Откуда» / «Куда» (`caption`, textTertiary) above the address (`bodyStrong`), or the placeholder «Выбрать на карте» (`body`, textTertiary);
  - when the place is set, a clear button (DkIconButton 48, `x`, «Очистить»);
  - otherwise a `chevron-right` 20 in textTertiary.
  - Read-only in trip details: no chevron, no clear button.
  - Each line is one line (§10: shrink to 85 %, then «…»).
- **DkRouteStats:** three DkSummaryTiles in a DkCard (padding 16, gap 12):
  - «Расстояние» «7,4 км»;
  - «За км» «324 ₸» — amount ÷ km, a whole number;
  - «За минуту» «109 ₸» — amount ÷ the trip's own minutes (end − start), a whole number (stage 3 review: «В пути» repeated «22 мин» from the line above).
- **DkTripTile** gets two optional parameters:
  - `route`: a line «Зелёный базар → ТРЦ Есентай Молл» (`caption`, textTertiary, one line, «…») under the time, meta and amount lines, across their full width. Beside the amounts it kept only «Зелёный базар → ТРЦ …»;
  - `onTap`: a trailing `chevron-right` 20 in textTertiary, 4 after the amounts and 8 from the edge, so the meta line keeps its room at 360 dp.
  - A trip without places stays read-only.
- **DkTextField** gets two additions:
  - `showLabel: false`: the label is only the accessible name, and the placeholder says it (the search over the map);
  - `onClear` + `clearLabel`: a clear button (48, `x`) at the end while there is text. It keeps its own width, unlike `trailing`, which takes half the row; the typed text gets the rest.
- **Icons:** `map` («Карта дня»), `map-pin` (search results), `search`, `route` («Построить заново»).

### 9.2 Add trip

- After the time row comes a DkListGroup with two DkPlaceFields, «Откуда» (A) and «Куда» (B). Both are optional.
  - Tapping one opens the place picker.
  - With only one set, an error under the group: «Укажите и начало, и конец поездки».
  - The server errors «Точка вне Алматы» and «Начало и конец совпадают» are shown the same way.
- Offline, the same-id resend is unchanged: the places are part of the trip.

### 9.3 Place picker

A full-screen pushed route; the map fills the screen.

**Top panel** (`surface`, safe area, padding 8 16 8 8):
- a close DkIconButton («Закрыть»);
- the search field: DkTextField with a `search` icon, no visible label, placeholder «Поиск адреса», and `onClear` («Очистить»).
- Under the panel, the suggestions: a DkCard of up to 5 DkListRows (icon `map-pin`, the label one line). Debounce 400 ms, from 3 characters.

**Center pin:** a DkPlaceMarker A or B, fixed at the center of the map.
- The map is exactly the area between the two panels, so its center is the chosen point.
- The panels do not overlap it.

**Bottom panel** (`surface`, shadow `e3`, padding 16, safe area):
- the label «Откуда» / «Куда» (`caption`, textTertiary);
- the address (`bodyStrong`, one line), updated after the map stops (reverse geocode, debounce 500 ms):
  - «Определяем адрес…» (textTertiary) while loading;
  - «Адрес не найден» (textSecondary) followed by the coordinates «43.2380, 76.9455» as the label;
- then a DkButton primary «Выбрать это место».

The attribution sits at the bottom right of the map, above the panel.

**Start view:** Almaty center 43.2389, 76.8897, zoom 12. If A is set, B starts at A. If the place was set before, the picker starts there at zoom 16.

**Offline:** the map shows its grey background, and an info row in the bottom panel says «Нет связи — карта не загрузилась». «Выбрать это место» still works and saves the center without a label (the coordinates are shown).

No GPS and no location permission in this iteration.

### 9.4 Trip details

A new pushed page with a back arrow and the title «Поездка».

**Map:**
- The top DkMapView takes 45 % of the screen height, full width, under the app bar, radius `lg` inside the 16 gutter.
- It shows the route with the A/B markers, fitted to the route.

**Below the map** (padding 16, gap 16):
- the time range (`titleM`, with «+1» when it ends the next day);
- «22 мин · Карта» (bodyS, textSecondary);
- the amount (`moneyM`) and «комиссия 360 ₸» (caption, textTertiary) on one DkAmountRow;
- DkRouteStats;
- a DkListGroup with the two DkPlaceFields, read-only.

**Status `straight`:**
- the route is dashed;
- under the map, a DkInfoRow «Маршрут построен по прямой — сервис карт был недоступен» and a DkButton text «Построить заново» (icon `route`), which calls `POST /trips/{id}/route`;
- distance and «За км» come from the straight line.

**Status `pending`:** the markers without a line, and «Расстояние» / «За км» show «—».

**States:**
- loading: a skeleton block of the map's height, then skeleton lines;
- error: DkErrorState with «Повторить»;
- tiles failing: a grey map with the attribution (§9.1).

### 9.5 Day screen and day map

**Trip rows:**
- A row with places is tappable: chevron, and the `route` line «Зелёный базар → ТРЦ Есентай Молл». It opens the trip details.
- Rows without places are unchanged.

**«Карта дня»:**
- A DkIconButton (`map`, «Карта дня») in the trips list header, before the sort button.
- It is shown only when at least one trip of the day has places.

**Day map:** a pushed page «Карта дня» with a full-height DkMapView. (Reworked after the stage 3 review: with A/B on every route it was unclear which line was which, and one trip's B hid under the next trip's A.)
- **Numbered routes.** The day's trips are numbered in time order (1, 2, …):
  - the start marker shows the trip's number (32 dp, `markerA`, 13/800);
  - the end marker is a 14 dp `markerB` dot with the 2 dp ring;
  - when a trip ends within 50 m of where the next one starts, one marker is drawn: the next trip's number (no dot under it).
  - Trip details keep A/B.
- **Selection.** Tapping a route or a list row selects that trip:
  - its route stays `routeLine` and is drawn over the others, which turn `routeMuted`;
  - the map fits to the selected route;
  - its row is shown selected (`accentSoft`);
  - tapping the same route or row again clears the selection (all routes `routeLine`, the map fits all).
- The fit covers every route and marker.
- A legend panel at the bottom (`surface`, shadow `e3`, full width, at most 40 % of the screen, scrolls):
  - «N маршрутов» (`titleM`) and the date (`caption`); for the admin, the filter first: «Все водители · 1 октября 2026», «Водитель 2 · 1 октября 2026»;
  - then the day's trips as DkListRows: the numbered marker (the same number as on the map), «08:10 – 08:32 · 2 400 ₸» over «Зелёный базар → ТРЦ Есентай Молл»;
  - a row tap selects the route (above); a trailing DkIconButton (`chevron-right`, «Открыть поездку») opens the trip details;
  - screen readers: each row reads «Маршрут 1 из 2» first, then its texts, and says when it is selected; the open button is its own node. The map's route taps are not semantics nodes.
- The admin sees the routes of the selected filter («Все водители» or one driver).

### 9.6 Formatting

- **Distance:**
  - under 1 000 m in metres, «850 м»;
  - from 1 000 m in kilometres with one decimal and a comma, «7,4 км»;
  - a no-break space before the unit (`DkFormat.distance`).
- **Per km:** amount × 1 000 ÷ metres, rounded to a whole tenge (`DkFormat.perKilometre`), then `DkMoney.format` («324 ₸», U+202F).
- **Per minute:** amount ÷ the trip's minutes, rounded (`DkFormat.perMinute`); none for a trip under a minute.
- **Coordinates as a label:** «43.2380, 76.9455» — 4 decimals, a dot (a point, not a number to read).

### 9.7 Copy (ru; kk goes to app_kk.arb)

From the prompt:
- «Откуда», «Куда», «Выбрать на карте», «Выбрать это место»;
- «Определяем адрес…», «Адрес не найден», «Поиск адреса»;
- «Расстояние», «За км», «Маршрут», «Карта дня» («В пути» is no longer used);
- «Маршрут построен по прямой — сервис карт был недоступен», «Построить заново»;
- «Начало поездки», «Конец поездки»;
- errors: «Укажите и начало, и конец поездки», «Точка вне Алматы», «Начало и конец совпадают».

From §9.3 offline: «Нет связи — карта не загрузилась».

Proposed, approved after stage 2 (kk machine-translated, needs native review):
- «Очистить» — the clear button;
- «Поездка» — the details title;
- «{n} маршрут / маршрута / маршрутов» — the day-map legend;
- units «м», «км».

Proposed in stage 3, approved:
- «За минуту» (kk «Минутына») — the third stat;
- «Данные карты» (kk «Карта деректері») — the credits sheet title and the attribution's accessible name.

Proposed with the day-map numbering (waiting for approval):
- «Маршрут {n} из {total}» (kk «Бағыт {n} / {total}») — spoken first on each day-map row;
- «Открыть поездку» (kk «Сапарды ашу») — the row's button.

### 9.8 Kit implementation (stage 2)

Components live in `packages/design_kit/lib/src/components/dk_map.dart`. Like the §8 components, they have **no texts of their own**.

**Showcase:**
- `packages/design_kit/example`, «Карты» tab, with a ru / kk switch;
- `example/test/maps_screens_test.dart` renders every state in ru and kk, light and dark, and checks no overflow at 360 dp × 1.3 and the money format.

| §9.1 item | Kit API |
|---|---|
| Tiles | `DkMapTiles(lightUrl, darkUrl, attribution, userAgentPackageName, provider)`. `darkens(brightness)`: the dark theme with no separate dark style. |
| DkMapView | `DkMapView(tiles, fit \| center + zoom, layers, overlays, controller, onMapEvent, interactive, rounded, animateTiles, attributionInsets, extraAttribution, onAttributionTap, attributionLabel, semanticsLabel)`. A fitted map fits again after its first frame and is rebuilt when its size or points change (flutter_map fits once). |
| DkRouteLayer | `DkRouteLayer(routes: [DkRoute(points, straight, id)], onTap, selected)`. `onTap` gives back the tapped route's `id`; `selected` draws that route last in `routeLine` and the others in `routeMuted` (the day map). |
| DkPlaceMarker | `DkPlaceMarker(kind: DkPlaceKind.start / end, semanticsLabel, number)` (a number instead of the letter) and `DkPlaceMarker.dot(semanticsLabel)` (14 dp end dot). On a map: `DkPlaceMarkers(places: [(point, kind, label)], markers: [(point, marker)])`. |
| DkPlaceField | `DkPlaceField(kind, label, markerLabel, value, placeholder, onTap, onClear, clearLabel)`; 64 high (`dkPlaceFieldHeight`). |
| DkRouteStats | `DkRouteStats(stats: [(label, value)])`. |
| DkTripTile | `route` and `onTap` (optional). |
| DkListRow | `leading` (a widget in the 40 slot), `selected` (`accentSoft`), `semanticsLabel` (spoken first), `trailingIsAction` (the trailing button stays its own node). |
| DkTextField | `showLabel`, `onClear` / `clearLabel`. |
| Formatting | `DkFormat.distance(metres, metresUnit, kilometresUnit)`, `DkFormat.perKilometre(amount, metres)`, `DkFormat.perMinute(amount, duration)`. |
| Credits | `showDkMapCredits(title, credits)` / `DkMapCredits`. |
| Tests and previews | `DkSketchTileProvider(offline)`: tiles drawn on the device (a street grid with parks and water), no network, the same picture every time. `offline: true` means tiles never arrive. |

## 10. Layout stability

Every control keeps its size; the text adapts inside it. A label that is longer than its control — a Kazakh text, a larger system font, a narrow phone — never makes the control taller or wider and never pushes the layout around. Audit of the old behaviour: `docs/UI_STABILITY_AUDIT.md`.

### 10.1 Rules

1. **Text scale is clamped to ×1.3** app-wide (`MediaQuery.withClampedTextScaling(maxScaleFactor: dkMaxTextScale)` in `MaterialApp.builder`). Up to it, everything follows the rules below. Why, and what it costs: DECISIONS.md.
2. **Fixed heights**, never content-driven:

   | Control | Height |
   |---|---|
   | `DkButton` | 56 (text and compact: 48) |
   | `DkFab` | 56 |
   | `DkSegmentedControl` (tabs, payment method) | 56 |
   | `DkLanguageSwitch` | 56 |
   | `DkFilterChips` | 40 chip, 48 tap area |
   | `DkBadge`, `DkStatusChip` | 24 |
   | `DkIconButton`, `DkTodayButton` | 48 |
   | `DkTextField`, `DkTimeField` (the box) | 56 |
   | `DkDaySwitcher` | 56 (title and subtitle scaled together) |
   | `DkListRow` | 56; **64 with a subtitle** (two-line variant) |
   | `DkSummaryTile` text block (summary and payment tiles) | **48** (label over amount) |
3. **Labels in these controls are one line.** A label that does not fit first scales down, to at most 85 % of its style size (`dkMinFitScale`). If it still does not fit:
   - a label that has a **short form** shows it (`DkLine.short`): the payment tile «Наличные · 38%» → «Наличные» (the split bar shows the share), the badge «+1 день» → «+1»;
   - otherwise it ends in «…».

   Screen readers always get the full text (the share, «+1 день»); a cut label also shows in a tooltip on long press. Labels never wrap and never grow their control, and shrinking to fit the width never changes their height. Kit: `DkFitText` / `DkFitLines`.
   - **Action buttons are never cut up to text ×1.15** (only at ×1.3). Tabs too.
   - Ensured by copy (rule 8): the 409 dialog's «Сохранить как новую» and the proposed Kazakh tab labels.
4. **Width.** Full-width buttons stay full width. Inline controls get a maximum width and follow rule 3 inside it:
   - FAB ≤ 60 % of the screen width (`dkFabMaxWidthShare`);
   - an inline button ≤ the content column (screen width − 2 gutters), even in an unbounded row;
   - a field's trailing button («Всё») ≤ half the field's inner row; its label shrinks with that space.
5. **Segmented controls and tabs:** segments share the width equally, and each label follows rule 3. Filter chips scroll horizontally and never wrap to a second row.
6. **Multi-line text is only for content:** body text, messages, helpers, errors, dialog titles and messages. Never inside a control. Dialog buttons follow rule 3; this replaces the earlier rule that let «Сохранить как новую поездку» wrap onto two lines.
7. **Amounts are never cut.** An amount is one line and shrinks to 85 % at most. In a row, the text column gives way first: its lines scale, then end in «…».
8. **Copy, not ellipsis:** where a label would end in «…» at 360 dp and text ×1.0 (action buttons: up to ×1.15), a shorter wording is proposed in `docs/L10N.md` (marked «предложено»). The layout test fails on any cut text at ×1.0.

### 10.2 Additions (stage 2 review)

- **A. Two-line controls** have a fixed two-line height: list row with a subtitle 64, day switcher 56, summary/payment tile text block 48. Each line follows rule 3; the lines scale **together** to fit the height (still ≥ 85 %). Nothing wraps inside them.
- **B. Decision buttons are never cut.** «Выплатить» / «Отклонить» (and the Kazakh labels) shrink to 85 % at most. If either label cannot fit in half the row at 85 %, the pair stacks: one above the other, both full width, each still 48 high (`DkAdaptivePair`).
  - The 409 dialog buttons are already stacked full width.
  - Where a dialog label still ends in «…» (only above ×1.0), a shorter wording is the fix (rule 8), not a second line.
- **C. Amounts in rows** (`DkAmountRow`, the trip row):
  - the amount column keeps at least 85 % of its width;
  - the text column gives way first;
  - if even that cannot fit, the amount column moves to its own line under the text. Digits are never cut.
- **Header** (`DkWordmark`, `DkPriorityRow`): the title shrinks to 85 % first, then the actions give way (the «Сегодня» pill shrinks, then ends in «…»), and only then is the title cut. The header never grows.

### 10.3 Kit API

| Need | Kit |
|---|---|
| One fitting line | `DkFitText(text, style, ellipsis: true, textAlign)` |
| Several lines that fit together | `DkFitLines([DkLine(text, style, ellipsis, trailing, short), DkLine.span(span, text: …), DkLine.money(amount)], gap)`. `ellipsis: false` = never cut (times, amounts); such a line reports 85 % of its width as its minimum intrinsic width. |
| Two controls that stack when they cannot fit | `DkAdaptivePair(first, second, gap)` |
| Text column + amount column | `DkAmountRow(start, end, gap)` |
| Title + actions | `DkPriorityRow(start, end, gap)` |
| Amount anywhere | `DkMoneyText` — one line, never cut, ≤ 85 % shrink |
| Badge with a short form | `DkBadge(text, short: …)` («+1 день» / «+1») |
| Limits | `dkMaxTextScale = 1.3`, `dkMinFitScale = 0.85`, `dkFabMaxWidthShare = 0.6`, `dkListRowTwoLineHeight = 64`, `dkTileTextHeight = 48` |

The lines are ordinary one-line `Text` widgets (`maxLines: 1`, `softWrap: false`), scaled when painted, so finders, semantics and the money-gap checks see real text.

Guards (fail the build): the kit size-invariance test (short vs 3× long label, ru/kk, ×1.0/1.15/1.3), the layout matrix (every control at its designed height, ×1.0/1.15/1.3), and the strict audit in CI (`AUDIT_STRICT=1 AUDIT_CHEAP=1`). See DECISIONS «UI stability — stage 4».

### 10.4 Deviations from the mockups

- **Summary and payment tiles are 6 dp taller** (text block 48 instead of 42 at ×1.0): the fixed height must hold label and amount at ×1.3 at 85 %.
- **List rows with a subtitle are 64** (8 dp more than the 56 minimum).
- **At ×1.15 and ×1.3 controls keep their ×1.0 height** (buttons 56, not 60–63); their labels shrink instead.
