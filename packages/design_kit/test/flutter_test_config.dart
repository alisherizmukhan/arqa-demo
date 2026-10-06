import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';

/// Goldens (alchemist):
/// - CI goldens (`goldens/ci/`): text drawn as blocks. Generated on Linux with
///   `tool/update_ci_goldens.sh` and compared only when `CI` is set (GitHub
///   Actions): even blocked text differs slightly between OSes.
/// - Platform goldens (`goldens/<os>/`): real Manrope / IBM Plex Sans, for
///   visual review and the README; generated and compared locally.
Future<void> testExecutable(FutureOr<void> Function() testMain) {
  final onCi = Platform.environment.containsKey('CI');
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(enabled: !onCi),
      ciGoldensConfig: CiGoldensConfig(enabled: onCi),
    ),
    run: () async {
      await testMain();
    },
  );
}
