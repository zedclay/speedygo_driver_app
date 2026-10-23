/// Server-authoritative offer countdown helpers.
///
/// [serverSkewMs] = localNowMs - serverNowMs estimated from HTTP Date header.
/// Remaining = expiresAtUtc - (localNow - skew).
Duration remainingUntilExpiry({
  required DateTime expiresAtUtc,
  required DateTime localNowUtc,
  int serverSkewMs = 0,
}) {
  final adjustedNow = localNowUtc.subtract(
    Duration(milliseconds: serverSkewMs),
  );
  final remaining = expiresAtUtc.difference(adjustedNow);
  if (remaining.isNegative) return Duration.zero;
  return remaining;
}

bool isOfferExpiredByServer({
  required DateTime expiresAtUtc,
  required DateTime localNowUtc,
  int serverSkewMs = 0,
}) {
  return remainingUntilExpiry(
        expiresAtUtc: expiresAtUtc,
        localNowUtc: localNowUtc,
        serverSkewMs: serverSkewMs,
      ) ==
      Duration.zero;
}

String formatCountdown(Duration remaining) {
  final totalSeconds = remaining.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');
  return '$mm:$ss';
}

/// Estimate local−server skew from an HTTP Date sample.
int estimateServerSkewMs({
  required DateTime localSampleUtc,
  required DateTime? serverSampleUtc,
}) {
  if (serverSampleUtc == null) return 0;
  return localSampleUtc.difference(serverSampleUtc).inMilliseconds;
}
