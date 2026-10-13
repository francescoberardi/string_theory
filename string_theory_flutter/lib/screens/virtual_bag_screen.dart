import 'dart:async';
import 'dart:collection';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:string_theory_client/string_theory_client.dart';

import '../bloc/bag_bloc.dart';
import '../client.dart';
import '../domain/workout_formatting.dart' as formatting;
import '../services/health/health_sync_service.dart';
import '../theme/court_midnight_theme.dart';
import '../widgets/add_racquet_modal.dart';
import '../widgets/bag/add_racquet_fab.dart';
import '../widgets/bag/app_navigation_destination.dart';
import '../widgets/bag/bag_bottom_nav.dart';
import '../widgets/bag/bag_empty_state.dart';
import '../widgets/bag/bag_error_view.dart';
import '../widgets/bag/bag_loading_indicator.dart';
import '../widgets/bag/bag_navigation_drawer.dart';
import '../widgets/bag/bag_navigation_rail.dart';
import '../widgets/bag/bag_racquet_list.dart';
import '../widgets/bag/bag_snack_bars.dart';
import '../widgets/bag/log_session_fab.dart';
import '../widgets/bag/pending_sync_banner.dart';
import '../widgets/bag/simulate_workout_badge.dart';
import 'sessions_screen.dart';
import '../widgets/health/health_permission_guidance.dart';
import '../widgets/workout_assignment_sheet.dart';
import 'settings_screen.dart';

export '../widgets/racquet_card.dart';

const double kMobileBreakpoint = VirtualBagScreen.kMobileBreakpoint;
const double kDesktopBreakpoint = VirtualBagScreen.kDesktopBreakpoint;

/// Screen displaying the virtual gear bag with responsive mobile/tablet layout
/// and an empty state demo bag seeder (Story 1.5).
class VirtualBagScreen extends StatefulWidget {
  final BagBloc? bagBloc;

  /// Overrides the [HealthSyncService] otherwise read from the context.
  final HealthSyncService? healthSyncService;

  /// Signs the user back in after an expired session; resolves to whether
  /// it succeeded. Defaults to `authService.loginAsGuest`, resolved at tap
  /// time.
  final Future<bool> Function()? onReauthenticate;

  const VirtualBagScreen({
    super.key,
    this.bagBloc,
    this.healthSyncService,
    this.onReauthenticate,
  });

  /// Shown when signing back in after an expired session fails.
  static const reauthFailedMessage =
      "Couldn't sign you in. Check your connection and try again.";

  static const double kMobileBreakpoint = 600.0;
  static const double kDesktopBreakpoint = 1024.0;

  static const keyEmptyState = BagEmptyState.keyEmptyState;
  static const keyEmptyAddButton = BagEmptyState.keyEmptyAddButton;
  static const keyLoadSampleBagButton = BagEmptyState.keyLoadSampleBagButton;
  static const keyRacquetList = BagRacquetList.keyRacquetList;
  static const keyRacquetGrid = BagRacquetList.keyRacquetGrid;
  static const keyBottomNav = BagBottomNav.keyBottomNav;
  static const keyNavigationRail = BagNavigationRail.keyNavigationRail;
  static const keyNavigationDrawer = BagNavigationDrawer.keyNavigationDrawer;
  static const keyLoadingIndicator = BagLoadingIndicator.keyLoadingIndicator;
  static const keySimulateWorkoutBadge =
      SimulateWorkoutBadge.keySimulateWorkoutBadge;
  static const keyLogSessionFab = LogSessionFab.keyLogSessionFab;
  static const keyPendingSyncBanner = PendingSyncBanner.keyPendingSyncBanner;

  /// Formats a workout duration as e.g. `1h 30m`, `2h` or `45m`.
  static String formatWorkoutDuration(int minutes) =>
      formatting.formatWorkoutDuration(minutes);

  @override
  State<VirtualBagScreen> createState() => _VirtualBagScreenState();
}

class _VirtualBagScreenState extends State<VirtualBagScreen>
    with WidgetsBindingObserver {
  int _navIndex = AppNavigationDestination.bag.index;
  HealthSyncService? _healthSyncService;
  StreamSubscription<DetectedWorkout>? _workoutSubscription;

  /// Detections received since the last frame, surfaced as one SnackBar.
  final _detectionBuffer = <DetectedWorkout>[];
  final _pendingWorkoutsQueue = Queue<DetectedWorkout>();
  bool _detectionFlushScheduled = false;
  bool _isAssignmentSheetOpen = false;
  DateTime? _lastSyncTime;
  static const _syncCooldown = Duration(seconds: 60);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncIfCooldownElapsed();
    }
  }

  void _syncIfCooldownElapsed() {
    final last = _lastSyncTime;
    final now = clock.now();
    if (last == null || now.difference(last) >= _syncCooldown) {
      _triggerSync();
    }
  }

  Future<void> _triggerSync() async {
    _lastSyncTime = clock.now();
    try {
      await _healthSyncService?.syncWorkouts();
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _presentNextPendingWorkout() {
    if (!mounted || _isAssignmentSheetOpen || _pendingWorkoutsQueue.isEmpty) {
      return;
    }
    final bloc = _resolveBloc(context);
    final currentState = bloc.state;
    final racquets = (currentState is BagLoaded)
        ? currentState.racquets
        : <Racquet>[];

    // Auto-open only over the bag tab itself; otherwise the Assign action
    // below remains the way in.
    final isBagVisible =
        _navIndex == AppNavigationDestination.bag.index &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    if (racquets.isEmpty || !isBagVisible) {
      return;
    }

    final nextWorkout = _pendingWorkoutsQueue.removeFirst();
    _openDetectedAssignmentSheet(nextWorkout, racquets, bloc);
  }

  Future<void> _openDetectedAssignmentSheet(
    DetectedWorkout workout,
    List<Racquet> racquets,
    BagBloc bloc,
  ) async {
    if (_isAssignmentSheetOpen) return;
    _isAssignmentSheetOpen = true;
    try {
      await WorkoutAssignmentSheet.showForDetected(
        context,
        workout: workout,
        racquets: racquets,
        bagBloc: bloc,
        healthSyncService: _healthSyncService,
      );
    } finally {
      if (mounted) {
        _isAssignmentSheetOpen = false;
        _presentNextPendingWorkout();
      }
    }
  }

  Future<void> _openManualAssignmentSheet(
    List<Racquet> racquets,
    BagBloc bloc,
  ) async {
    if (_isAssignmentSheetOpen) return;
    _isAssignmentSheetOpen = true;
    try {
      await WorkoutAssignmentSheet.showForManual(
        context,
        racquets: racquets,
        bagBloc: bloc,
        healthSyncService: _healthSyncService,
      );
    } finally {
      if (mounted) {
        _isAssignmentSheetOpen = false;
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bindHealthSyncService(
      widget.healthSyncService ?? context.read<HealthSyncService>(),
    );
  }

  @override
  void didUpdateWidget(covariant VirtualBagScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.healthSyncService != oldWidget.healthSyncService) {
      _bindHealthSyncService(
        widget.healthSyncService ?? context.read<HealthSyncService>(),
      );
    }
  }

  void _bindHealthSyncService(HealthSyncService service) {
    if (identical(service, _healthSyncService)) return;
    _workoutSubscription?.cancel();
    _healthSyncService = service;
    _workoutSubscription = service.workouts.listen(_onWorkoutDetected);
    // Pull recently completed workouts (no-op when simulated).
    _triggerSync();
  }

  /// Buffers detections arriving within the same frame (e.g. one sync that
  /// finds several workouts) so each batch yields a single SnackBar.
  void _onWorkoutDetected(DetectedWorkout workout) {
    if (!mounted) return;
    _detectionBuffer.add(workout);
    if (_detectionFlushScheduled) return;
    _detectionFlushScheduled = true;
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) => _flushDetections());
    binding.ensureVisualUpdate();
  }

  void _flushDetections() {
    _detectionFlushScheduled = false;
    final batch = List.of(_detectionBuffer);
    _detectionBuffer.clear();
    if (!mounted || batch.isEmpty) return;

    _pendingWorkoutsQueue.addAll(batch);

    final message = switch (batch) {
      [final workout] =>
        '${formatting.formatWorkoutDuration(workout.durationMinutes)} '
            'Tennis Match Detected',
      _ => '${batch.length} Tennis Matches Detected',
    };

    if (!_isAssignmentSheetOpen) {
      _presentNextPendingWorkout();
    }

    // Replace any detection still on screen instead of queueing behind it.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        buildDetectionSnackBar(
          message: message,
          onAssign: () {
            // The SnackBar can outlive this screen.
            if (!mounted) return;
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            if (_isAssignmentSheetOpen) return;
            final bloc = _resolveBloc(context);
            final activeState = bloc.state;
            final targetWorkout = _pendingWorkoutsQueue.isNotEmpty
                ? _pendingWorkoutsQueue.removeFirst()
                : batch.first;
            _openDetectedAssignmentSheet(
              targetWorkout,
              activeState is BagLoaded ? activeState.racquets : <Racquet>[],
              bloc,
            );
          },
        ),
      );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _workoutSubscription?.cancel();
    super.dispose();
  }

  BagBloc _resolveBloc(BuildContext context) {
    if (widget.bagBloc != null) {
      return widget.bagBloc!;
    }
    return context.read<BagBloc>();
  }

  bool _isTextEditingActive() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null) return false;
    final widget = focus.context?.widget;
    if (widget is EditableText) return true;
    return focus.context?.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  void _handleLogShortcut(BagState state) {
    if (_isTextEditingActive()) return;
    final bloc = _resolveBloc(context);
    final racquets = (state is BagLoaded) ? state.racquets : <Racquet>[];
    _openManualAssignmentSheet(racquets, bloc);
  }

  void _handleNewRacquetShortcut() {
    if (_isTextEditingActive()) return;
    AddRacquetModal.show(context, bagBloc: _resolveBloc(context));
  }

  void _handleSimulateShortcut() {
    if (_isTextEditingActive()) return;
    if (_healthSyncService?.supportsSimulation ?? false) {
      _healthSyncService?.simulateWorkout();
    }
  }

  void _handleEscapeShortcut() {
    Navigator.maybePop(context);
  }

  /// Re-provisions a session after a 401, then reloads the bag.
  Future<void> _reauthenticate() async {
    final signIn = widget.onReauthenticate ?? authService.loginAsGuest;
    bool signedIn;
    try {
      signedIn = await signIn();
    } catch (e) {
      debugPrint('VirtualBagScreen: re-authentication failed: $e');
      signedIn = false;
    }
    if (!mounted) return;
    if (signedIn) {
      _resolveBloc(context).add(const LoadBag());
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          buildErrorSnackBar(VirtualBagScreen.reauthFailedMessage),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBloc = widget.bagBloc ?? context.read<BagBloc>();
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < VirtualBagScreen.kMobileBreakpoint;
    final isDesktop = width > VirtualBagScreen.kDesktopBreakpoint;
    final crossAxisCount = isDesktop ? 3 : 2;

    return BlocConsumer<BagBloc, BagState>(
      bloc: effectiveBloc,
      // Keep the list (and its RefreshIndicator) mounted while a refresh
      // reloads the bag.
      buildWhen: (previous, current) =>
          !(current is BagLoading &&
              previous is BagLoaded &&
              previous.racquets.isNotEmpty),
      listener: (context, state) {
        if (state is BagLoaded && state.infoMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              buildInfoSnackBar(
                message: state.infoMessage!,
                hasPendingSync: state.pendingSyncCount > 0,
              ),
            );
        }
        if (state is BagLoaded && state.successMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(buildSuccessSnackBar(state.successMessage!));
        }
        if (state is BagLoaded && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            buildErrorSnackBar(
              state.errorMessage!,
              onSignIn: state.reauthRequired ? _reauthenticate : null,
            ),
          );
        }
      },
      builder: (context, state) {
        final content = switch (AppNavigationDestination.fromIndex(_navIndex)) {
          AppNavigationDestination.sessions => SessionsScreen(
            bagBloc: _resolveBloc(context),
            racquets: state is BagLoaded ? state.racquets : null,
            healthSyncService: _healthSyncService,
          ),
          _ => _buildBodyForState(context, state, isMobile, crossAxisCount),
        };

        final Widget scaffold;
        if (isMobile) {
          scaffold = Scaffold(
            backgroundColor: CourtMidnightTheme.background,
            body: SafeArea(child: content),
            bottomNavigationBar: BagBottomNav(
              currentIndex: _navIndex,
              onTap: (index) => _onNavigationTapped(context, index),
            ),
            floatingActionButton: _buildFab(context, state),
          );
        } else if (isDesktop) {
          scaffold = Scaffold(
            backgroundColor: CourtMidnightTheme.background,
            body: SafeArea(
              child: Row(
                children: [
                  BagNavigationDrawer(
                    selectedIndex: _navIndex,
                    onDestinationSelected: (index) =>
                        _onNavigationTapped(context, index),
                  ),
                  Expanded(child: content),
                ],
              ),
            ),
            floatingActionButton: _buildFab(context, state),
          );
        } else {
          // Tablet layout (600dp <= width <= 1024dp)
          scaffold = Scaffold(
            backgroundColor: CourtMidnightTheme.background,
            body: SafeArea(
              child: Row(
                children: [
                  BagNavigationRail(
                    selectedIndex: _navIndex,
                    onDestinationSelected: (index) =>
                        _onNavigationTapped(context, index),
                  ),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: CourtMidnightTheme.surfaceBorder,
                  ),
                  Expanded(child: content),
                ],
              ),
            ),
            floatingActionButton: _buildFab(context, state),
          );
        }

        return CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.keyL): () =>
                _handleLogShortcut(state),
            const SingleActivator(LogicalKeyboardKey.keyN):
                _handleNewRacquetShortcut,
            const SingleActivator(LogicalKeyboardKey.keyS):
                _handleSimulateShortcut,
            const SingleActivator(LogicalKeyboardKey.escape):
                _handleEscapeShortcut,
          },
          child: Focus(
            autofocus: true,
            child: scaffold,
          ),
        );
      },
    );
  }

  void _onNavigationTapped(BuildContext context, int index) {
    final destination = AppNavigationDestination.fromIndex(index);
    if (destination == null) return;

    switch (destination) {
      case AppNavigationDestination.account:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SettingsScreen(
              bagBloc: _resolveBloc(context),
            ),
          ),
        );
      case AppNavigationDestination.bag:
      case AppNavigationDestination.sessions:
        setState(() => _navIndex = destination.index);
    }
  }

  Widget? _buildFab(BuildContext context, BagState state) {
    if (_navIndex != AppNavigationDestination.bag.index) return null;
    final racquets = state is BagLoaded ? state.racquets : const <Racquet>[];
    final hasRacquets = racquets.isNotEmpty;
    final showBadge = _healthSyncService?.supportsSimulation ?? false;

    final children = <Widget>[
      if (showBadge)
        SimulateWorkoutBadge(
          onTap: () => _healthSyncService?.simulateWorkout(),
        ),
      if (showBadge && hasRacquets) const SizedBox(height: 12),
      if (hasRacquets)
        LogSessionFab(
          onPressed: () =>
              _openManualAssignmentSheet(racquets, _resolveBloc(context)),
        ),
      if (hasRacquets) const SizedBox(height: 12),
      if (hasRacquets)
        AddRacquetFab(
          onPressed: () =>
              AddRacquetModal.show(context, bagBloc: _resolveBloc(context)),
        ),
    ];

    if (children.isEmpty) return null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: children,
    );
  }

  Widget _buildBodyForState(
    BuildContext context,
    BagState state,
    bool isMobile,
    int crossAxisCount,
  ) {
    if (state is BagError) {
      return BagErrorView(
        message: state.message,
        onReload: () => _resolveBloc(context).add(const LoadBag()),
      );
    }

    if (state is BagLoaded) {
      final body = state.racquets.isEmpty
          ? BagEmptyState(
              onAddRacquet: () => AddRacquetModal.show(
                context,
                bagBloc: _resolveBloc(context),
              ),
              onLoadSampleBag: () =>
                  _resolveBloc(context).add(const SeedSampleBag()),
            )
          : BagRacquetList(
              racquets: state.racquets,
              bloc: _resolveBloc(context),
              isMobile: isMobile,
              crossAxisCount: crossAxisCount,
            );
      final hasPendingSync = state.pendingSyncCount > 0;
      final showPermissionGuidance =
          _healthSyncService != null && !_healthSyncService!.hasPermission;

      if (!hasPendingSync && !showPermissionGuidance) return body;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showPermissionGuidance)
            HealthPermissionGuidance(
              isMobile: isMobile,
              onRequestPermission: () => _triggerSync(),
            ),
          if (hasPendingSync)
            PendingSyncBanner(
              count: state.pendingSyncCount,
              isMobile: isMobile,
            ),
          Expanded(child: body),
        ],
      );
    }

    // BagLoading and BagInitial
    return const BagLoadingIndicator();
  }
}
