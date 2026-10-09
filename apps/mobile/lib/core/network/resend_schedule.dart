/// Waits between automatic resends of a create (trip or withdrawal) whose
/// outcome is unknown after a network/server failure (DESIGN.md §5.9,
/// §8.4): 2 s, 4 s, 8 s, then every 30 s while the screen is open. Every
/// resend reuses the same id, so the server never stores it twice.
const resendDelays = [
  Duration(seconds: 2),
  Duration(seconds: 4),
  Duration(seconds: 8),
  Duration(seconds: 30),
];

/// The wait before resend number [attempt] (0-based).
Duration resendDelay(int attempt) =>
    resendDelays[attempt < resendDelays.length
        ? attempt
        : resendDelays.length - 1];
