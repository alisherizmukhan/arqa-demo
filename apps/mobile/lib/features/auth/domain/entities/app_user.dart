import 'package:meta/meta.dart';

/// What an account may do: a driver keeps a diary and withdraws, an admin
/// sees all drivers and decides withdrawals.
enum UserRole { driver, admin }

/// The signed-in account.
@immutable
final class AppUser {
  const new({
    required this.id,
    required this.login,
    required this.role,
    required this.displayName,
  });

  final String id;
  final String login;
  final UserRole role;

  /// «Водитель 1».
  final String displayName;

  bool get isAdmin => role == UserRole.admin;

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.id == id &&
      other.login == login &&
      other.role == role &&
      other.displayName == displayName;

  @override
  int get hashCode => Object.hash(id, login, role, displayName);

  @override
  String toString() => 'AppUser($login, ${role.name})';
}
