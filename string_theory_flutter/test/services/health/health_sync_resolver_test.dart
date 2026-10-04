import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:string_theory_flutter/services/health/health_sync_resolver.dart';
import 'package:string_theory_flutter/services/health/native_health_sync_service.dart';
import 'package:string_theory_flutter/services/health/simulated_health_sync_service.dart';

void main() {
  group('createHealthSyncService', () {
    test('binds SimulatedHealthSyncService on web', () {
      final service = createHealthSyncService(
        isWeb: true,
        platform: TargetPlatform.iOS,
      );
      addTearDown(service.dispose);

      expect(service, isA<SimulatedHealthSyncService>());
      expect(service.supportsSimulation, isTrue);
    });

    for (final platform in [
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.linux,
    ]) {
      test('binds SimulatedHealthSyncService on ${platform.name}', () {
        final service = createHealthSyncService(
          isWeb: false,
          platform: platform,
        );
        addTearDown(service.dispose);

        expect(service, isA<SimulatedHealthSyncService>());
      });
    }

    for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
      test('binds NativeHealthSyncService on ${platform.name}', () {
        final service = createHealthSyncService(
          isWeb: false,
          platform: platform,
        );
        addTearDown(service.dispose);

        expect(service, isA<NativeHealthSyncService>());
        expect(service.supportsSimulation, isFalse);
      });
    }

    test('falls back to defaultTargetPlatform when no override is given', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final service = createHealthSyncService(isWeb: false);
      addTearDown(service.dispose);

      expect(service, isA<SimulatedHealthSyncService>());
    });
  });
}
