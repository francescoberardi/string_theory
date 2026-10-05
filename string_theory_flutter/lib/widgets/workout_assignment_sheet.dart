import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:string_theory_client/string_theory_client.dart';

import '../bloc/bag_bloc.dart';
import '../services/health/health_sync_service.dart';
import '../theme/court_midnight_theme.dart';
import 'workout_assignment/advanced_options_panel.dart';
import 'workout_assignment/advanced_options_toggle.dart';
import 'workout_assignment/assignment_sheet_frame.dart';
import 'workout_assignment/confirm_button.dart';
import 'workout_assignment/court_surface_selector.dart';
import 'workout_assignment/detected_workout_header.dart';
import 'workout_assignment/duration_selector.dart';
import 'workout_assignment/manual_log_header.dart';
import 'workout_assignment/racquet_selector.dart';

/// Progressive disclosure bottom sheet for assigning detected tennis workouts
/// or manual quick logging (<10 seconds).
class WorkoutAssignmentSheet extends StatefulWidget {
  final DetectedWorkout? workout;
  final List<Racquet> racquets;
  final BagBloc bagBloc;
  final HealthSyncService? healthSyncService;

  const WorkoutAssignmentSheet({
    super.key,
    this.workout,
    required this.racquets,
    required this.bagBloc,
    this.healthSyncService,
  });

  static const keyConfirmButton = ConfirmButton.keyConfirmButton;
  static const keyAdvancedToggle = AdvancedOptionsToggle.keyAdvancedToggle;
  static const keyNotesField = AdvancedOptionsPanel.keyNotesField;

  static Key keyRacquetTile(int id) => RacquetSelector.keyRacquetTile(id);
  static Key keySurfaceChip(String surface) =>
      CourtSurfaceSelector.keySurfaceChip(surface);
  static Key keyDurationChip(String duration) =>
      DurationSelector.keyDurationChip(duration);

  /// Shows why no session can be logged yet and returns true, or returns
  /// false when at least one racquet is strung.
  static bool _explainIfUnloggable(
    BuildContext context,
    List<Racquet> racquets,
  ) {
    final String message;
    if (racquets.isEmpty) {
      message = 'Please add a racquet to your bag first';
    } else if (!racquets.any((r) => r.activeStringJob != null)) {
      message = 'Restring a racquet before logging court time';
    } else {
      return false;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: CourtMidnightTheme.surface,
        content: Text(
          message,
          style: GoogleFonts.inter(color: CourtMidnightTheme.textPrimary),
        ),
      ),
    );
    return true;
  }

  /// Displays the assignment sheet for an automated or simulated workout.
  static Future<void> showForDetected(
    BuildContext context, {
    required DetectedWorkout workout,
    required List<Racquet> racquets,
    required BagBloc bagBloc,
    HealthSyncService? healthSyncService,
  }) {
    if (_explainIfUnloggable(context, racquets)) return Future.value();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WorkoutAssignmentSheet(
        workout: workout,
        racquets: racquets,
        bagBloc: bagBloc,
        healthSyncService: healthSyncService,
      ),
    );
  }

  /// Displays the manual quick logger with preset duration chips.
  static Future<void> showForManual(
    BuildContext context, {
    required List<Racquet> racquets,
    required BagBloc bagBloc,
    HealthSyncService? healthSyncService,
  }) {
    if (_explainIfUnloggable(context, racquets)) return Future.value();

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WorkoutAssignmentSheet(
        racquets: racquets,
        bagBloc: bagBloc,
        healthSyncService: healthSyncService,
      ),
    );
  }

  @override
  State<WorkoutAssignmentSheet> createState() => _WorkoutAssignmentSheetState();
}

class _WorkoutAssignmentSheetState extends State<WorkoutAssignmentSheet> {
  late int? _selectedRacquetId;
  int _selectedDurationMinutes = 60;
  bool _isAdvancedExpanded = false;
  bool _isSubmitting = false;
  String? _selectedCourtSurface;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();

    final primary = widget.racquets
        .where((r) => r.isPrimary && r.activeStringJob != null)
        .firstOrNull;
    final firstStrung = widget.racquets
        .where((r) => r.activeStringJob != null)
        .firstOrNull;
    _selectedRacquetId = primary?.id ?? firstStrung?.id;

    if (widget.workout != null) {
      _selectedDurationMinutes = widget.workout!.durationMinutes;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (_isSubmitting) return;
    final racquetId = _selectedRacquetId;
    if (racquetId == null) return;

    final selectedRacquet = widget.racquets
        .where((r) => r.id == racquetId)
        .firstOrNull;
    if (selectedRacquet == null || selectedRacquet.activeStringJob == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final trimmedNotes = _notesController.text.trim();
    final notes = trimmedNotes.isEmpty ? null : trimmedNotes;
    final courtSurface = _selectedCourtSurface;

    if (widget.workout != null) {
      final w = widget.workout!;
      final healthSyncService = widget.healthSyncService;
      widget.bagBloc.add(
        LogSession(
          racquetId: racquetId,
          startTime: w.startTime,
          durationMinutes: w.durationMinutes,
          courtSurface: courtSurface,
          notes: notes,
          source: w.source,
          externalWorkoutId: w.externalWorkoutId,
          // Keep the workout pending until the server accepts it, so a
          // failed log can be retried.
          onLogged: () =>
              healthSyncService?.dismissPendingWorkout(w.externalWorkoutId),
        ),
      );
    } else {
      // A quick log is entered after play, so the session ended now.
      final endTime = DateTime.now().toUtc();
      widget.bagBloc.add(
        LogSession(
          racquetId: racquetId,
          startTime: endTime.subtract(
            Duration(minutes: _selectedDurationMinutes),
          ),
          durationMinutes: _selectedDurationMinutes,
          courtSurface: courtSurface,
          notes: notes,
          source: 'manual',
          externalWorkoutId: null,
        ),
      );
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final workout = widget.workout;

    return AssignmentSheetFrame(
      footer: ConfirmButton(
        onPressed: (_selectedRacquetId != null && !_isSubmitting)
            ? _onConfirm
            : null,
        isSubmitting: _isSubmitting,
      ),
      children: [
        if (workout != null)
          DetectedWorkoutHeader(workout: workout)
        else ...[
          const ManualLogHeader(),
          const SizedBox(height: 16),
          DurationSelector(
            selectedMinutes: _selectedDurationMinutes,
            onSelected: (minutes) =>
                setState(() => _selectedDurationMinutes = minutes),
          ),
        ],
        const SizedBox(height: 20),
        RacquetSelector(
          racquets: widget.racquets,
          selectedRacquetId: _selectedRacquetId,
          onSelected: (id) => setState(() => _selectedRacquetId = id),
        ),
        const SizedBox(height: 16),
        AdvancedOptionsToggle(
          isExpanded: _isAdvancedExpanded,
          onToggle: () =>
              setState(() => _isAdvancedExpanded = !_isAdvancedExpanded),
        ),
        AdvancedOptionsPanel(
          isExpanded: _isAdvancedExpanded,
          selectedSurface: _selectedCourtSurface,
          onSurfaceChanged: (surface) =>
              setState(() => _selectedCourtSurface = surface),
          notesController: _notesController,
        ),
      ],
    );
  }
}
