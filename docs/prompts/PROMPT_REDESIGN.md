# Промпт: редизайн по утверждённым макетам

Использован 6 октября 2026 (этапы R1–R6). Восстановлен дословно из сессии, в которой был вставлен.

```
Redesign only. Bring the existing Flutter UI to the approved mockups exactly. Do NOT change backend code, API contracts or domain logic.

Sources of truth:
- DESIGN.md (repo root): tokens, components, screens, states, copy, formatting.
- docs/design/*.png: mockups at @2x (780×1688 px = 390×844 dp; divide measured pixels by 2).
  01_day_light, 02_day_dark, 03_day_empty, 04_day_loading, 05_day_error, 06_day_trip_added,
  07_add_trip, 08_add_trip_errors, 09_add_trip_saving, 10_add_trip_offline,
  11_add_trip_midnight, 12_add_trip_conflict_409 (+ optional 13_kit_tokens, 14_kit_components).
If the PNG and DESIGN.md disagree, DESIGN.md wins — note the case in docs/DECISIONS.md.
Do not invent colors, sizes, radii, fonts or texts. Do not use any design-generation skill.

Work in stages. After each stage stop, show screenshots side by side with the matching PNG, and wait for my "ok".

1. Audit. Compare the current app with DESIGN.md and every PNG. Write docs/DESIGN_AUDIT.md: a checklist grouped by tokens / components / screens / states / copy / formatting. No code changes.

2. Tokens (packages/design_kit). Implement DESIGN.md §2 exactly as ThemeExtensions: DkColors, DkTypography, DkSpacing, DkRadii, DkElevation, DkSizes (light + dark, copyWith, lerp) and DkTheme.light()/dark(). Bundle Manrope (500/600/700/800) as assets of the package; tabular figures in every text style. No shadows in dark. Copy DESIGN.md into packages/design_kit/DESIGN.md.

3. Components (packages/design_kit). Bring all components to DESIGN.md §4: DkButton (primary/secondary/text × enabled/disabled/loading), DkFab, DkCard, DkSummaryCard, DkSummaryTile, DkSplitBar, DkTripTile (card/cash, +1, highlighted, read-only), DkDaySwitcher, DkTextField (default/focused/error/disabled; time and money variants; trailing badge), DkBadge, DkSegmentedControl, DkSnackbar (error with action, compact success), DkDialog, DkEmptyState, DkErrorState, DkSkeleton (line/box + summaryCard/paymentCard/tripTile). Update example/ to show every component in every state, light and dark. Add golden tests (alchemist or golden_toolkit) for the list in DESIGN.md §7.

4. Screens (apps/mobile). Rebuild Day and Add trip from kit components only, matching 01–12 one by one, including every state in DESIGN.md §5. Add trip is a full-screen modal route with the Save button pinned at the bottom. Remove every hardcoded Color/Colors./TextStyle/EdgeInsets literal/radius from apps/mobile; add a CI step that fails if `grep -R "Color(0x\|Colors\.\|TextStyle(" apps/mobile/lib` finds anything.

5. UI behavior that comes with the design (presentation layer only; reuse existing use cases/repository):
   - formatting per DESIGN.md §3: U+202F between thousands and before ₸, U+2212 for commission in the summary, "Сегодня"/"Вчера" labels, plural поездка/поездки/поездок, duration "22 мин" / "1 ч 5 мин";
   - cross-midnight entry: end ≤ start on the clock → next day, "+1 день" badge and helper; error only if duration is 0 or > 12 h; "+1" superscript in the trip list;
   - inline validation texts from DESIGN.md §6; Save disabled while errors exist; server 422 field errors shown on the same fields;
   - 409 → DkDialog with stored values from the response ("Оставить сохранённую" / "Сохранить как новую поездку"). If the API does not return the stored trip, show the dialog without the values and list this in DESIGN_AUDIT.md — do not change the backend;
   - offline → DkSnackbar with "Повторить"; retries keep the same trip id;
   - after save → back to the day of the trip start, new row highlighted ~2 s, success snackbar "Поездка добавлена" next to the FAB;
   - pull-to-refresh keeps data visible; refresh failure → snackbar, not the full error screen.

6. Final check. Walk through DESIGN.md §7 and DESIGN_AUDIT.md, tick every item, update README screenshots (light + dark Day, Add trip, one error state), and add to docs/AI_NOTES.md where the AI deviated from the mockup and how it was caught.

Constraints: small Conventional Commits; flutter analyze / dart analyze with zero warnings; all existing tests stay green; text scale 1.3 must not clip anything on Day and Add trip.
```
