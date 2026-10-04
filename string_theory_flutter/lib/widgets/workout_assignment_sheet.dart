import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:string_theory_client/string_theory_client.dart';

import '../bloc/bag_bloc.dart';
import '../services/health/health_sync_service.dart';
import '../theme/court_midnight_theme.dart';

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

  static const keyConfirmButton = Key('workout_assignment_confirm_button');
  static const keyAdvancedToggle = Key('workout_assignment_advanced_toggle');
  static const keyNotesField = Key('workout_assignment_notes_field');

  static Key keyRacquetTile(int id) => Key('workout_assignment_racquet_$id');
  static Key keySurfaceChip(String surface) =>
      Key('workout_assignment_surface_${surface.toLowerCase()}');
  static Key keyDurationChip(String duration) =>
      Key('workout_assignment_duration_$duration');

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

  static const _durationPresets = [
    ('30m', 30),
    ('1h', 60),
    ('1.5h', 90),
    ('2h', 120),
  ];

  static const _surfaces = ['Hard', 'Clay', 'Grass', 'Carpet'];

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

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    if (hours == 0) return '${rest}m';
    if (rest == 0) return '${hours}h';
    return '${hours}h ${rest}m';
  }

  String _formatStartTime(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    final isToday =
        local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour:$minute $period';

    if (isToday) {
      return 'Today, $timeStr';
    } else {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[local.month - 1]} ${local.day}, $timeStr';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDetected = widget.workout != null;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: CourtMidnightTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: CourtMidnightTheme.surfaceBorder),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Top drag pill
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CourtMidnightTheme.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title and duration pill/chips
                      if (isDetected) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'ASSIGN WORKOUT',
                              style: GoogleFonts.barlowCondensed(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: CourtMidnightTheme.textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: CourtMidnightTheme.primaryVolt
                                    .withValues(
                                      alpha: 0.15,
                                    ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: CourtMidnightTheme.primaryVolt,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                _formatDuration(
                                  widget.workout!.durationMinutes,
                                ),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: CourtMidnightTheme.primaryVolt,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatStartTime(widget.workout!.startTime),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: CourtMidnightTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tennis workout detected via ${widget.workout!.source}. Attribute court time to a racquet.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: CourtMidnightTheme.textSecondary,
                          ),
                        ),
                      ] else ...[
                        Text(
                          'LOG COURT SESSION',
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: CourtMidnightTheme.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select duration and attribute court time to your active stringbed.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: CourtMidnightTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Duration chips row
                        Row(
                          children: _durationPresets.map((preset) {
                            final (label, minutes) = preset;
                            final isSelected =
                                _selectedDurationMinutes == minutes;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Semantics(
                                  button: true,
                                  selected: isSelected,
                                  child: InkWell(
                                    key: WorkoutAssignmentSheet.keyDurationChip(
                                      label,
                                    ),
                                    onTap: () => setState(
                                      () => _selectedDurationMinutes = minutes,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      height: 48,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? CourtMidnightTheme.primaryVolt
                                                  .withValues(
                                                    alpha: 0.15,
                                                  )
                                            : CourtMidnightTheme.background,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? CourtMidnightTheme.primaryVolt
                                              : CourtMidnightTheme
                                                    .surfaceBorder,
                                          width: isSelected ? 1.5 : 1.0,
                                        ),
                                      ),
                                      child: Text(
                                        label,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? CourtMidnightTheme.primaryVolt
                                              : CourtMidnightTheme
                                                    .textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Racquet selector header
                      Text(
                        'SELECT RACQUET',
                        style: GoogleFonts.barlowCondensed(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                          color: CourtMidnightTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Horizontal racquet carousel
                      SizedBox(
                        height: 84,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.racquets.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final racquet = widget.racquets[index];
                            final isStrung = racquet.activeStringJob != null;
                            final isSelected =
                                isStrung && racquet.id == _selectedRacquetId;
                            final stringModel =
                                racquet.activeStringJob?.model ?? 'Unstrung';

                            return Semantics(
                              button: true,
                              selected: isSelected,
                              enabled: isStrung,
                              child: InkWell(
                                key: WorkoutAssignmentSheet.keyRacquetTile(
                                  racquet.id ?? index,
                                ),
                                onTap: isStrung
                                    ? () {
                                        setState(() {
                                          _selectedRacquetId = racquet.id;
                                        });
                                      }
                                    : null,
                                borderRadius: BorderRadius.circular(14),
                                child: Opacity(
                                  opacity: isStrung ? 1.0 : 0.45,
                                  child: Container(
                                    width: 160,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? CourtMidnightTheme.primaryVolt
                                                .withValues(
                                                  alpha: 0.10,
                                                )
                                          : CourtMidnightTheme.background,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isSelected
                                            ? CourtMidnightTheme.primaryVolt
                                            : CourtMidnightTheme.surfaceBorder,
                                        width: isSelected ? 2.0 : 1.0,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                racquet.name,
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: CourtMidnightTheme
                                                      .textPrimary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (!isStrung)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                  left: 4,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 5,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: CourtMidnightTheme
                                                      .healthCritical
                                                      .withValues(alpha: 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'UNSTRUNG',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w800,
                                                    color: CourtMidnightTheme
                                                        .healthCritical,
                                                  ),
                                                ),
                                              )
                                            else if (racquet.isPrimary)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                  left: 4,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 5,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: CourtMidnightTheme
                                                      .primaryVolt,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'PRI',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w900,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          stringModel,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: CourtMidnightTheme
                                                .textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Progressive disclosure accordion toggle
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: InkWell(
                            key: WorkoutAssignmentSheet.keyAdvancedToggle,
                            onTap: () {
                              setState(() {
                                _isAdvancedExpanded = !_isAdvancedExpanded;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isAdvancedExpanded
                                        ? Icons.remove_circle_outline
                                        : Icons.add_circle_outline,
                                    size: 18,
                                    color: CourtMidnightTheme.primaryVolt,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isAdvancedExpanded
                                        ? '- Fewer Options'
                                        : '+ Advanced Options',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: CourtMidnightTheme.primaryVolt,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Accordion contents
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: _isAdvancedExpanded
                            ? Padding(
                                padding: const EdgeInsets.only(
                                  top: 12,
                                  bottom: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'COURT SURFACE',
                                      style: GoogleFonts.barlowCondensed(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.6,
                                        color: CourtMidnightTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: _surfaces.map((surface) {
                                        final isSelected =
                                            _selectedCourtSurface == surface;
                                        return Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                            child: Semantics(
                                              button: true,
                                              selected: isSelected,
                                              child: InkWell(
                                                key:
                                                    WorkoutAssignmentSheet.keySurfaceChip(
                                                      surface,
                                                    ),
                                                onTap: () {
                                                  setState(() {
                                                    _selectedCourtSurface =
                                                        isSelected
                                                        ? null
                                                        : surface;
                                                  });
                                                },
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: Container(
                                                  height: 48,
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? CourtMidnightTheme
                                                              .primaryVolt
                                                              .withValues(
                                                                alpha: 0.15,
                                                              )
                                                        : CourtMidnightTheme
                                                              .background,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    border: Border.all(
                                                      color: isSelected
                                                          ? CourtMidnightTheme
                                                                .primaryVolt
                                                          : CourtMidnightTheme
                                                                .surfaceBorder,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    surface,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 13,
                                                      fontWeight: isSelected
                                                          ? FontWeight.w700
                                                          : FontWeight.w500,
                                                      color: isSelected
                                                          ? CourtMidnightTheme
                                                                .primaryVolt
                                                          : CourtMidnightTheme
                                                                .textSecondary,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'SESSION NOTES',
                                      style: GoogleFonts.barlowCondensed(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.6,
                                        color: CourtMidnightTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      key: WorkoutAssignmentSheet.keyNotesField,
                                      controller: _notesController,
                                      maxLines: 2,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: CourtMidnightTheme.textPrimary,
                                      ),
                                      decoration: InputDecoration(
                                        hintText:
                                            'e.g. Heavy baseline rallies, match tiebreak...',
                                        hintStyle: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: CourtMidnightTheme
                                              .textSecondary
                                              .withValues(alpha: 0.6),
                                        ),
                                        filled: true,
                                        fillColor:
                                            CourtMidnightTheme.background,
                                        contentPadding: const EdgeInsets.all(
                                          12,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: CourtMidnightTheme
                                                .surfaceBorder,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color: CourtMidnightTheme
                                                .surfaceBorder,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: const BorderSide(
                                            color:
                                                CourtMidnightTheme.primaryVolt,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),

              // Full-width Confirm button pinned at the bottom
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    key: WorkoutAssignmentSheet.keyConfirmButton,
                    onPressed: (_selectedRacquetId != null && !_isSubmitting)
                        ? _onConfirm
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CourtMidnightTheme.primaryVolt,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: CourtMidnightTheme.surfaceBorder,
                      disabledForegroundColor: CourtMidnightTheme.textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Text(
                            'Confirm',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
