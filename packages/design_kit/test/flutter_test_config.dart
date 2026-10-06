import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';

/// Goldens (alchemist):
/// - CI goldens (`goldens/ci/`): text drawn as blocks, identical on every OS,
///   compared everywhere including GitHub Actions.
/// - Platform goldens (`goldens/<os>/`): real Manrope / IBM Plex Sans, for
///   visual review and the README; generated locally, skipped when `CI` is set
///   because font rasterisation differs between operating systems.
Future<void> testExecutable(FutureOr<void> Function() testMain) {
  final onCi = Platform.environment.containsKey('CI');
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(enabled: !onCi),
      ciGoldensConfig: const CiGoldensConfig(),
    ),
    run: () async {
      await testMain();
    },
  );
}
