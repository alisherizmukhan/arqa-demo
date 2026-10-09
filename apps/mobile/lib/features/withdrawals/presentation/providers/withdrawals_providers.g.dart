// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'withdrawals_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(withdrawalsRepository)
final withdrawalsRepositoryProvider = WithdrawalsRepositoryProvider._();

final class WithdrawalsRepositoryProvider
    extends
        $FunctionalProvider<
          WithdrawalsRepository,
          WithdrawalsRepository,
          WithdrawalsRepository
        >
    with $Provider<WithdrawalsRepository> {
  WithdrawalsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'withdrawalsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$withdrawalsRepositoryHash();

  @$internal
  @override
  $ProviderElement<WithdrawalsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WithdrawalsRepository create(Ref ref) {
    return withdrawalsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WithdrawalsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WithdrawalsRepository>(value),
    );
  }
}

String _$withdrawalsRepositoryHash() =>
    r'986866d39719b32e02d22e04be90341afcec6446';

/// The balance: the signed-in driver's, or (admin) [driverId]'s.

@ProviderFor(balance)
final balanceProvider = BalanceFamily._();

/// The balance: the signed-in driver's, or (admin) [driverId]'s.

final class BalanceProvider
    extends $FunctionalProvider<AsyncValue<Balance>, Balance, FutureOr<Balance>>
    with $FutureModifier<Balance>, $FutureProvider<Balance> {
  /// The balance: the signed-in driver's, or (admin) [driverId]'s.
  BalanceProvider._({
    required BalanceFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'balanceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$balanceHash();

  @override
  String toString() {
    return r'balanceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Balance> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Balance> create(Ref ref) {
    final argument = this.argument as String?;
    return balance(ref, driverId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BalanceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$balanceHash() => r'a254b434e9e7cd19433a7b05b71bda26cc8b9759';

/// The balance: the signed-in driver's, or (admin) [driverId]'s.

final class BalanceFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Balance>, String?> {
  BalanceFamily._()
    : super(
        retry: null,
        name: r'balanceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The balance: the signed-in driver's, or (admin) [driverId]'s.

  BalanceProvider call({String? driverId}) =>
      BalanceProvider._(argument: driverId, from: this);

  @override
  String toString() => r'balanceProvider';
}

/// Withdrawals, newest first: the driver's own, or (admin) everyone's,
/// optionally only [status].

@ProviderFor(withdrawals)
final withdrawalsProvider = WithdrawalsFamily._();

/// Withdrawals, newest first: the driver's own, or (admin) everyone's,
/// optionally only [status].

final class WithdrawalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Withdrawal>>,
          List<Withdrawal>,
          FutureOr<List<Withdrawal>>
        >
    with $FutureModifier<List<Withdrawal>>, $FutureProvider<List<Withdrawal>> {
  /// Withdrawals, newest first: the driver's own, or (admin) everyone's,
  /// optionally only [status].
  WithdrawalsProvider._({
    required WithdrawalsFamily super.from,
    required WithdrawalStatus? super.argument,
  }) : super(
         retry: null,
         name: r'withdrawalsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$withdrawalsHash();

  @override
  String toString() {
    return r'withdrawalsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Withdrawal>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Withdrawal>> create(Ref ref) {
    final argument = this.argument as WithdrawalStatus?;
    return withdrawals(ref, status: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WithdrawalsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$withdrawalsHash() => r'b386cd6dd237290a6ba65797c70ee89b0d229f05';

/// Withdrawals, newest first: the driver's own, or (admin) everyone's,
/// optionally only [status].

final class WithdrawalsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<Withdrawal>>,
          WithdrawalStatus?
        > {
  WithdrawalsFamily._()
    : super(
        retry: null,
        name: r'withdrawalsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Withdrawals, newest first: the driver's own, or (admin) everyone's,
  /// optionally only [status].

  WithdrawalsProvider call({WithdrawalStatus? status}) =>
      WithdrawalsProvider._(argument: status, from: this);

  @override
  String toString() => r'withdrawalsProvider';
}

/// The id of a just-created withdrawal, highlighted for ~2 s (§8.4).

@ProviderFor(HighlightedWithdrawal)
final highlightedWithdrawalProvider = HighlightedWithdrawalProvider._();

/// The id of a just-created withdrawal, highlighted for ~2 s (§8.4).
final class HighlightedWithdrawalProvider
    extends $NotifierProvider<HighlightedWithdrawal, String?> {
  /// The id of a just-created withdrawal, highlighted for ~2 s (§8.4).
  HighlightedWithdrawalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'highlightedWithdrawalProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$highlightedWithdrawalHash();

  @$internal
  @override
  HighlightedWithdrawal create() => HighlightedWithdrawal();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$highlightedWithdrawalHash() =>
    r'6c6de25f74f793c00539c377350ebca112450340';

/// The id of a just-created withdrawal, highlighted for ~2 s (§8.4).

abstract class _$HighlightedWithdrawal extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Sending a withdrawal. Lives as long as the withdraw screen.

@ProviderFor(WithdrawController)
final withdrawControllerProvider = WithdrawControllerProvider._();

/// Sending a withdrawal. Lives as long as the withdraw screen.
final class WithdrawControllerProvider
    extends $AsyncNotifierProvider<WithdrawController, Withdrawal?> {
  /// Sending a withdrawal. Lives as long as the withdraw screen.
  WithdrawControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'withdrawControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$withdrawControllerHash();

  @$internal
  @override
  WithdrawController create() => WithdrawController();
}

String _$withdrawControllerHash() =>
    r'1b3507d3b9bf12ffea7e24a89d344b5fd0484a32';

/// Sending a withdrawal. Lives as long as the withdraw screen.

abstract class _$WithdrawController extends $AsyncNotifier<Withdrawal?> {
  FutureOr<Withdrawal?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Withdrawal?>, Withdrawal?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Withdrawal?>, Withdrawal?>,
              AsyncValue<Withdrawal?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
