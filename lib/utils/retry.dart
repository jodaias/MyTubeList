import 'dart:async';
import 'dart:math';

/// Executes [fn] with retry and exponential backoff.
///
/// Retries up to [maxAttempts] times. The delay between retries
/// starts at [initialDelay] and doubles on each attempt, capped at
/// [maxDelay]. Optional jitter avoids thundering-herd.
///
/// If [retryIf] is provided, only exceptions matching the predicate
/// are retried; all others are rethrown immediately.
Future<T> retryWithBackoff<T>(
  Future<T> Function() fn, {
  int maxAttempts = 3,
  Duration initialDelay = const Duration(seconds: 1),
  Duration maxDelay = const Duration(seconds: 8),
  bool Function(Exception)? retryIf,
}) async {
  final random = Random();
  var delay = initialDelay;

  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } on Exception catch (e) {
      if (attempt == maxAttempts) rethrow;
      if (retryIf != null && !retryIf(e)) rethrow;

      // Add jitter: 0-25% of the current delay
      final jitter = Duration(
        milliseconds:
            (delay.inMilliseconds * random.nextDouble() * 0.25).toInt(),
      );
      await Future.delayed(delay + jitter);

      // Exponential backoff, capped at maxDelay
      delay = Duration(
        milliseconds: min(delay.inMilliseconds * 2, maxDelay.inMilliseconds),
      );
    }
  }

  // Unreachable, but keeps the compiler happy
  return fn();
}
