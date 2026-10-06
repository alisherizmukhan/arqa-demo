# Design — Driver Shift Diary

Design kit for a fintech-style app used by ride-hailing drivers: check today's earnings at a glance between trips, often in a car mount, in sunlight or at night.

## How this was derived (ui-ux-pro-max)

The design pass used the **ui-ux-pro-max** skill (v. installed 2026-10-06):

```
search.py "fintech earnings tracker mobile driver high contrast" --design-system
search.py "fintech banking earnings" --domain color
search.py "dashboard numbers cyrillic sans" --domain typography
search.py "theme extension dark mode tokens" --stack flutter
search.py "skeleton loading state" / "tabular figures numbers" --domain ux
```

| Skill output | Decision |
|---|---|
| **Style: Dark Mode (OLED)** — deep black, high contrast, "dark bg + green positive indicators" | **Kept** for the dark theme (night driving, OLED, low emission). |
| "Light mode not recommended" | **Rejected.** Drivers also work in daylight with sun glare, which needs a *high-contrast light* theme. Both themes ship and follow the system setting. |
| Palette: slate neutrals, accent **green `#22C55E`** for positive figures | **Kept** as the dark-theme primary/positive color. For light, darkened to green-700 `#15803D` so it passes 4.5:1 on white (`#22C55E` is only 2.3:1). |
| Fintech/Crypto palette (gold + purple) | Rejected: crypto connotation; amber is used only as the *cash* accent. |
| Typography: Inter + **Playfair Display** body | Rejected: a serif display face for body text hurts glanceability. |
| Typography: **"Financial Trust — IBM Plex Sans"** (fintech/banking, "excellent for data") | **Chosen.** Verified with fontTools: Cyrillic ✓, `₸` U+20B8 ✓, no-break spaces ✓, and **tabular digits by default** (all digits 600 units wide), so totals never shift width while updating. DM Sans was also suggested but has no Cyrillic. |
| Pattern "Enterprise Gateway" (landing page with mega menu) | Rejected: a landing-page pattern, not applicable to a two-screen mobile app. |
| UX rules: 48dp targets, 8dp gaps, visible labels, color-not-only, skeletons, reduced motion, number formatting | **Applied** — see the checklist below; most are enforced by tests. |

## Principles

1. **One hero figure.** The net payout (`Чистыми`) is the largest thing on screen (44sp bold, green). Everything else is secondary.
2. **High contrast, both themes.** Every text pair ≥ 4.5:1, control outlines ≥ 3:1 (`test/contrast_test.dart`).
3. **Big targets.** Minimum 48dp; buttons, inputs and segments are 56dp; list rows 64dp; ≥ 8dp between targets.
4. **Never color alone.** Cash/card always have an icon *and* a label; commission has a minus sign; errors have text.
5. **Money is integer tenge, formatted `3 315 ₸`** — grouped with no-break spaces (U+00A0), so a figure never wraps; negatives use the real minus `−`.
6. **Russian UI text** in the kit's defaults (`Повторить`, `Наличные`, `Предыдущий день`, …), overridable via parameters.

## Tokens

All tokens are `ThemeExtension`s, read via `context.dkColors`, `context.dkText`, `context.dkSpacing`, `context.dkRadii`, `context.dkSizes`. Components never use raw values.

### Colors

| Token | Light | Dark | Use |
|---|---|---|---|
| background | `#F8FAFC` | `#020617` | Screen |
| surface | `#FFFFFF` | `#0F172A` | Cards, inputs |
| surfaceMuted | `#F1F5F9` | `#1E293B` | Skeletons, icon badges |
| border | `#E2E8F0` | `#334155` | Decorative dividers |
| outline | `#64748B` | `#64748B` | Control boundaries (4.8 / 3.8 : 1) |
| textPrimary | `#0F172A` | `#F8FAFC` | Text, figures (17.9 / 17.1 : 1) |
| textSecondary | `#475569` | `#94A3B8` | Labels (7.6 / 7.0 : 1) |
| primary / onPrimary | `#15803D` / `#FFFFFF` | `#22C55E` / `#052E16` | Main actions (5.0 / 6.5 : 1) |
| positive | `#15803D` | `#4ADE80` | Net payout (5.0 / 10.3 : 1) |
| cash | `#B45309` | `#FBBF24` | Cash icon accent |
| card | `#1D4ED8` | `#60A5FA` | Card icon accent |
| error | `#B91C1C` | `#F87171` | Errors (6.5 / 6.5 : 1) |

### Type (IBM Plex Sans, variable font, tabular digits)

| Token | Size / weight | Use |
|---|---|---|
| moneyHero | 44 / 700 | Net payout |
| moneyLarge | 26 / 600 | Summary totals |
| moneyMedium | 20 / 600 | Trip amounts |
| title | 20 / 600 | App bar, screen titles |
| titleSmall | 17 / 600 | Day label, state titles |
| body | 16 / 400, line-height 1.5 | Running text |
| bodyStrong | 16 / 500 | Buttons, trip times |
| label | 14 / 500 | Field labels, captions — the smallest size in the kit |

### Spacing · radii · sizes · motion

- Spacing (4/8 rhythm): `4 · 8 · 12 · 16 · 24 · 32 · 48`
- Radii: `8` (skeleton) · `12` (buttons, inputs) · `16` (cards) · pill
- Sizes: touch target `48`, control height `56`, list row `64`, icons `20 / 24 / 48`
- Motion: `150 ms` feedback, `250 ms` cross-fade, `1200 ms` skeleton pulse; **no animation when `MediaQuery.disableAnimations`** is on.

## Components

`DkButton` (primary / secondary / text, loading, disabled) · `DkCard` · `DkSummaryTile.money / .count` (hero / regular, tones, deduction) · `DkTripTile` · `DkDaySwitcher` · `DkEmptyState` · `DkErrorState` · `DkSkeleton` · `DkTextField` · `DkSegmentedControl` (added for the payment-method choice) · `DkMoney.format`.

Run the showcase: `cd packages/design_kit/example && flutter run -d chrome` (`?theme=dark` opens the dark theme on web).

## Checklist (from the skill, verified)

- [x] Text contrast ≥ 4.5:1 and outlines ≥ 3:1 in **both** themes — unit-tested per token pair
- [x] Flutter `androidTapTargetGuideline`, `iOSTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline` pass for a gallery of all interactive components in light and dark
- [x] Touch targets ≥ 48dp, 8dp spacing between adjacent targets
- [x] Visible labels on inputs (not placeholder-only), errors below the field
- [x] Color is never the only signal (payment icon + label, minus sign, error text)
- [x] Loading button keeps its look, ignores taps and announces `Загрузка`
- [x] Skeletons instead of spinners for content; still under reduced motion
- [x] Vector icons from one family (Material outlined), no emoji
- [x] No overflow on a 360dp-wide phone in either theme (example app test)
- [x] Large figures scale down instead of wrapping (`FittedBox`), tabular digits

## Not done / known limits

- No golden tests: rendering differs between Windows and the Linux CI runner; screenshots are taken from the web build instead.
- Dynamic Type: figures scale down to fit at large text sizes rather than wrapping; other text wraps normally. Not tested at 200%.
