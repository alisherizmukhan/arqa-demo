# design_kit

Design tokens, light/dark themes and components for Driver Shift Diary. Independent of the app (`apps/mobile` depends on it, never the reverse).

```dart
MaterialApp(theme: DkTheme.light(), darkTheme: DkTheme.dark(), ...);

DkSummaryTile.money(label: 'Чистыми', amount: 3315, tone: DkTone.positive,
    emphasis: DkSummaryEmphasis.hero);           // 3 315 ₸
Padding(padding: EdgeInsets.all(context.dkSpacing.md), ...);
```

- Design rationale, tokens and the accessibility checklist: [DESIGN.md](DESIGN.md)
- Showcase of every component: `example/` (`flutter run -d chrome`, add `?theme=dark` for the dark theme)
- Font: IBM Plex Sans, unmodified, SIL Open Font License 1.1 (`fonts/OFL.txt`)
