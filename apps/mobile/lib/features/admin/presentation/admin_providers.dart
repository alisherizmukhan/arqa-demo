import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/core/providers.dart';
import 'package:driver_diary/features/admin/data/admin_repository_impl.dart';
import 'package:driver_diary/features/admin/domain/admin.dart';
import 'package:driver_diary/features/auth/domain/entities/app_user.dart';
import 'package:driver_diary/features/auth/presentation/providers/session_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'admin_providers.g.dart';

@Riverpod(keepAlive: true)
AdminRepository adminRepository(Ref ref) =>
    AdminRepositoryImpl(ref.watch(dioProvider));

/// The drivers (filter chips, row labels, the «Водители» tab).
@riverpod
Future<List<Account>> drivers(Ref ref) async {
  ref.watch(currentUserIdProvider);
  final result = await ref.watch(adminRepositoryProvider).accounts();
  return switch (result) {
    Ok(:final value) => [
      for (final account in value)
        if (account.user.role == UserRole.driver) account,
    ],
    Err(:final failure) => throw failure,
  };
}

/// Driver id → display name («Водитель 1»), for the rows of all drivers.
@riverpod
Map<String, String> driverNames(Ref ref) => {
  for (final account in ref.watch(driversProvider).value ?? const <Account>[])
    account.user.id: account.user.displayName,
};
