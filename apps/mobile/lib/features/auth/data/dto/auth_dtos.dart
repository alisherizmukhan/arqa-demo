import 'package:driver_diary/features/auth/domain/entities/app_user.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_dtos.freezed.dart';
part 'auth_dtos.g.dart';

/// An account as the API returns it (`UserOut`).
@freezed
abstract class UserDto with _$UserDto {
  const factory({
    required String id,
    required String login,
    required String role,
    @JsonKey(name: 'display_name') required String displayName,
  }) = _UserDto;

  const new _();

  factory fromJson(Map<String, Object?> json) => _$UserDtoFromJson(json);

  /// Throws [FormatException] on an unknown role.
  AppUser toDomain() => AppUser(
    id: id,
    login: login,
    role: switch (role) {
      'driver' => UserRole.driver,
      'admin' => UserRole.admin,
      _ => throw FormatException('unknown role', role),
    },
    displayName: displayName,
  );
}

/// `POST /auth/login` response.
@freezed
abstract class LoginResponseDto with _$LoginResponseDto {
  const factory({required String token, required UserDto user}) =
      _LoginResponseDto;

  factory fromJson(Map<String, Object?> json) =>
      _$LoginResponseDtoFromJson(json);
}
