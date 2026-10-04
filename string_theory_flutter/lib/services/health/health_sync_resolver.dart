import 'package:flutter/foundation.dart';

import 'health_sync_service.dart';
import 'native_health_sync_service.dart';
import 'simulated_health_sync_service.dart';

/// Binds the [HealthSyncService] strategy for the current platform:
/// native on iOS / Android, simulated on web and desktop.
///
/// Uses [kIsWeb] / [defaultTargetPlatform] rather than `dart:io` so it is
/// safe on web.
HealthSyncService createHealthSyncService({
  bool? isWeb,
  TargetPlatform? platform,
}) {
  if (isWeb ?? kIsWeb) return SimulatedHealthSyncService();

  return switch (platform ?? defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.android => NativeHealthSyncService(),
    _ => SimulatedHealthSyncService(),
  };
}
