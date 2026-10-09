import 'package:driver_diary/core/error/failure.dart';
import 'package:driver_diary/core/error/result.dart';
import 'package:driver_diary/core/l10n/locale_providers.dart';
import 'package:driver_diary/features/admin/domain/admin.dart';
import 'package:driver_diary/features/auth/data/token_store.dart';
import 'package:driver_diary/features/auth/domain/entities/app_user.dart';
import 'package:driver_diary/features/auth/domain/repositories/auth_repository.dart';
import 'package:driver_diary/features/withdrawals/domain/entities/withdrawal.dart';
import 'package:driver_diary/features/withdrawals/domain/repositories/withdrawals_repository.dart';

const driver1 = AppUser(
  id: 'u1',
  login: 'user_1',
  role: UserRole.driver,
  displayName: 'Водитель 1',
);
const driver2 = AppUser(
  id: 'u2',
  login: 'user_2',
  role: UserRole.driver,
  displayName: 'Водитель 2',
);
const adminUser = AppUser(
  id: 'a1',
  login: 'admin',
  role: UserRole.admin,
  displayName: 'Администратор',
);

/// Passwords of the fake accounts.
const fakePasswords = {
  'user_1': 'password_1',
  'user_2': 'password_2',
  'admin': 'admin',
};

/// Accounts by login; [onLogin] / [onMe] replace the default answers.
class FakeAuthRepository implements AuthRepository {
  new({this.signedIn});

  /// Whose token the store holds (`GET /auth/me` answers with it).
  AppUser? signedIn;
  int logouts = 0;
  final List<String> logins = [];
  Future<Result<SignedInSession>> Function(String login, String password)?
  onLogin;
  Future<Result<AppUser>> Function()? onMe;

  static const Map<String, AppUser> _users = {
    'user_1': driver1,
    'user_2': driver2,
    'admin': adminUser,
  };

  @override
  Future<Result<SignedInSession>> login(String login, String password) async {
    logins.add(login);
    if (onLogin case final answer?) return await answer(login, password);
    final user = _users[login];
    if (user == null || fakePasswords[login] != password) {
      return const Err(UnauthorizedFailure(code: 'invalid_credentials'));
    }
    signedIn = user;
    return Ok((token: 'token-${user.login}', user: user));
  }

  @override
  Future<Result<AppUser>> me() async {
    if (onMe case final answer?) return await answer();
    final user = signedIn;
    return user == null ? const Err(UnauthorizedFailure()) : Ok(user);
  }

  @override
  Future<Result<void>> logout() async {
    logouts++;
    signedIn = null;
    return const Ok(null);
  }
}

class MemoryTokenStore implements TokenStore {
  new([this.token]);

  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String token) async => this.token = token;

  @override
  Future<void> clear() async => token = null;
}

class MemoryLocaleStore implements LocaleStore {
  new([this.code]);

  String? code;

  @override
  String? read() => code;

  @override
  Future<void> write(String code) async => this.code = code;
}

final oct9 = DateTime.utc(2026, 10, 9, 17, 34); // 22:34 +05:00

/// One driver's money; [onCreate] etc. replace the default answers.
class FakeWithdrawalsRepository implements WithdrawalsRepository {
  new({
    this.cardTotal = 2400,
    this.commissionTotal = 585,
    List<Withdrawal> items = const [],
  }) : items = [...items];

  int cardTotal;
  int commissionTotal;
  final List<Withdrawal> items;
  final creates = <({String id, int amount})>[];
  final decisions = <String>[];
  Future<Result<Withdrawal>> Function(String id, int amount)? onCreate;
  Future<Result<Balance>> Function()? onBalance;
  Future<Result<Withdrawal>> Function(String id)? onDecide;

  int get withdrawnTotal => items
      .where((w) => w.status != WithdrawalStatus.rejected)
      .fold(0, (sum, w) => sum + w.amount);

  Balance get current => Balance(
    available: cardTotal - commissionTotal - withdrawnTotal,
    cardTotal: cardTotal,
    commissionTotal: commissionTotal,
    withdrawnTotal: withdrawnTotal,
  );

  @override
  Future<Result<Balance>> balance({String? driverId}) async {
    if (onBalance case final answer?) return await answer();
    return Ok(current);
  }

  @override
  Future<Result<List<Withdrawal>>> withdrawals({
    String? driverId,
    WithdrawalStatus? status,
  }) async => Ok([
    for (final w in items.reversed)
      if (status == null || w.status == status) w,
  ]);

  @override
  Future<Result<Withdrawal>> create({
    required String id,
    required int amount,
  }) async {
    creates.add((id: id, amount: amount));
    if (onCreate case final answer?) return await answer(id, amount);
    final existing = items.where((w) => w.id == id).firstOrNull;
    if (existing != null) {
      return existing.amount == amount
          ? Ok(existing)
          : const Err(ConflictFailure('conflict', 'withdrawal_conflict'));
    }
    if (amount > current.available) {
      return const Err(
        ValidationFailure(
          code: 'insufficient_funds',
          message: 'too much',
          field: 'amount',
        ),
      );
    }
    final created = Withdrawal(
      id: id,
      driverId: driver1.id,
      amount: amount,
      status: WithdrawalStatus.pending,
      createdAt: oct9,
    );
    items.add(created);
    return Ok(created);
  }

  Future<Result<Withdrawal>> _decide(
    String id,
    WithdrawalStatus status, [
    String? reason,
  ]) async {
    decisions.add('$id:${status.name}${reason == null ? '' : ':$reason'}');
    if (onDecide case final answer?) return await answer(id);
    final index = items.indexWhere((w) => w.id == id);
    final w = items[index];
    final decided = Withdrawal(
      id: w.id,
      driverId: w.driverId,
      amount: w.amount,
      status: status,
      createdAt: w.createdAt,
      rejectReason: reason,
    );
    items[index] = decided;
    return Ok(decided);
  }

  @override
  Future<Result<Withdrawal>> approve(String id) =>
      _decide(id, WithdrawalStatus.paid);

  @override
  Future<Result<Withdrawal>> reject(String id, String reason) =>
      _decide(id, WithdrawalStatus.rejected, reason);
}

class FakeAdminRepository implements AdminRepository {
  final accountsList = [
    const Account(user: driver1, isActive: true),
    const Account(user: driver2, isActive: true),
    const Account(user: adminUser, isActive: true),
  ];
  final revoked = <String>[];
  Future<Result<Account>> Function(String id, {required bool active})?
  onSetActive;

  @override
  Future<Result<List<Account>>> accounts() async => Ok([...accountsList]);

  @override
  Future<Result<Account>> setActive(
    String userId, {
    required bool active,
  }) async {
    if (onSetActive case final answer?) {
      return await answer(userId, active: active);
    }
    final index = accountsList.indexWhere((a) => a.user.id == userId);
    final updated = Account(user: accountsList[index].user, isActive: active);
    accountsList[index] = updated;
    return Ok(updated);
  }

  @override
  Future<Result<int>> revokeSessions(String userId) async {
    revoked.add(userId);
    return const Ok(1);
  }
}
