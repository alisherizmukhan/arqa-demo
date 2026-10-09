import 'dart:async';

import 'package:design_kit/design_kit.dart';
import 'package:driver_diary/core/l10n/l10n.dart';
import 'package:driver_diary/core/l10n/locale_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// «Русский» / «Қазақша» (each in its own language); applies at once and is
/// remembered (DESIGN.md §8.1, §8.3).
class LanguageSwitch extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return DkLanguageSwitch(
      languages: [
        (code: 'ru', name: l10n.languageRu),
        (code: 'kk', name: l10n.languageKk),
      ],
      selected: ref.watch(appLocaleProvider).languageCode,
      onChanged: (code) =>
          unawaited(ref.read(appLocaleProvider.notifier).select(code)),
    );
  }
}
