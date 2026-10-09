import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Icon mapping, DESIGN.md §2.7 (Lucide outline icons).
///
/// Lucide ships stroke weights as separate fonts (w400 = 2.0, w500 = 2.5).
/// The spec's 2.4 (plus, chevron-down) uses w500 and its 2.2 (inline error)
/// uses w400 — the nearest available weights.
abstract final class DkIcons {
  /// Previous day.
  static const IconData previous = LucideIcons.chevronLeft400;

  /// Next day.
  static const IconData next = LucideIcons.chevronRight400;

  /// Date picker hint (stroke 2.4 → w500).
  static const IconData chevronDown = LucideIcons.chevronDown500;

  /// Jump to today.
  static const IconData today = LucideIcons.calendarCheck400;

  /// Header button that opens the Menu.
  static const IconData menu = LucideIcons.circleUserRound400;

  /// Profile tile in the Menu.
  static const IconData user = LucideIcons.userRound400;

  /// Withdrawals.
  static const IconData wallet = LucideIcons.wallet400;

  /// Language.
  static const IconData languages = LucideIcons.languages400;

  /// Log out.
  static const IconData logOut = LucideIcons.logOut400;

  /// Info line.
  static const IconData info = LucideIcons.info400;

  /// Show password.
  static const IconData eye = LucideIcons.eye400;

  /// Hide password.
  static const IconData eyeOff = LucideIcons.eyeOff400;

  /// Pending status.
  static const IconData pending = LucideIcons.clock400;

  /// Rejected status.
  static const IconData rejected = LucideIcons.circleX400;

  /// Block an account.
  static const IconData block = LucideIcons.ban400;

  /// Unblock an account.
  static const IconData unblock = LucideIcons.lockOpen400;

  /// End all sessions of an account.
  static const IconData signOutEverywhere = LucideIcons.monitorSmartphone400;

  /// Sort order of a list.
  static const IconData sort = LucideIcons.arrowUpDown400;

  /// The selected option in a list.
  static const IconData check = LucideIcons.check400;

  /// Cash.
  static const IconData cash = LucideIcons.banknote400;

  /// Card.
  static const IconData card = LucideIcons.creditCard400;

  /// Add (stroke 2.4 → w500).
  static const IconData add = LucideIcons.plus500;

  /// Close.
  static const IconData close = LucideIcons.x400;

  /// Time field.
  static const IconData time = LucideIcons.clock400;

  /// Inline error and dialog (stroke 2.2 → w400).
  static const IconData alert = LucideIcons.circleAlert400;

  /// Load error.
  static const IconData loadError = LucideIcons.cloudOff400;

  /// No connection.
  static const IconData offline = LucideIcons.wifiOff400;

  /// Retry.
  static const IconData retry = LucideIcons.rotateCw400;

  /// Saved.
  static const IconData saved = LucideIcons.circleCheck400;

  /// Empty state: Lucide `road` (matches the mockup and DESIGN.md's
  /// "(road)"; Lucide's `route` is a connected path). The glyph is in the
  /// package's fonts but has no Dart constant in this version.
  static const IconData empty = IconData(
    0xE6D9,
    fontFamily: 'Lucide400',
    fontPackage: 'lucide_icons_flutter',
  );
}
