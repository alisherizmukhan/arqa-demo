import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/features/auth/domain/entities/app_user.dart';
import 'package:meta/meta.dart';

/// An account as the admin sees it.
@immutable
final class Account {
  const new({required this.user, required this.isActive});

  final AppUser user;

  /// False: blocked (cannot sign in; its sessions no longer work).
  final bool isActive;

  @override
  bool operator ==(Object other) =>
      other is Account && other.user == user && other.isActive == isActive;

  @override
  int get hashCode => Object.hash(user, isActive);
}

abstract interface class AdminRepository {
  /// All accounts, drivers first.
  Future<Result<List<Account>>> accounts();

  /// Blocks or unblocks; demo accounts → `ConflictFailure`
  /// (`demo_account_protected`).
  Future<Result<Account>> setActive(String userId, {required bool active});

  /// Signs the account out everywhere; returns how many sessions ended.
  Future<Result<int>> revokeSessions(String userId);
}
