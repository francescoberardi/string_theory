import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:string_theory_client/string_theory_client.dart';

import '../bloc/bag_bloc.dart';
import '../domain/decay_engine.dart';
import '../theme/court_midnight_theme.dart';
import 'add_racquet_modal.dart' show StringCategoryDefaults;
import 'workout_assignment/assignment_sheet_frame.dart';

/// "Restrung Today" decision sheet (Story 4.2): reset the stringbed to 100%
/// with the previous specs in one tap, or expand the form to change them.
class RestringSheet extends StatefulWidget {
  final Racquet racquet;
  final BagBloc bagBloc;

  const RestringSheet({
    super.key,
    required this.racquet,
    required this.bagBloc,
  });

  static const keySheet = Key('restring_sheet');
  static const keyKeepSameButton = Key('restring_keep_same_button');
  static const keyChangeSpecsToggle = Key('restring_change_specs_toggle');
  static const keyBrandField = Key('restring_brand_field');
  static const keyModelField = Key('restring_model_field');
  static const keyTensionField = Key('restring_tension_field');
  static const keyCategoryField = Key('restring_category_field');
  static const keySubmitButton = Key('restring_submit_button');

  /// Opens the sheet over [context] as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required Racquet racquet,
    required BagBloc bagBloc,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RestringSheet(racquet: racquet, bagBloc: bagBloc),
    );
  }

  @override
  State<RestringSheet> createState() => _RestringSheetState();
}

class _RestringSheetState extends State<RestringSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _tensionController;
  late StringMaterialCategory _category;
  late double _maxHours;
  bool _isChangingSpecs = false;

  @override
  void initState() {
    super.initState();
    final job = widget.racquet.activeStringJob;
    _brandController = TextEditingController(text: job?.brand ?? '');
    _modelController = TextEditingController(text: job?.model ?? '');
    _tensionController = TextEditingController(
      text: job?.installedTension?.toString() ?? '',
    );
    _category = job?.materialCategory ?? StringMaterialCategory.coPoly;
    _maxHours =
        job?.maxRatedHours ?? StringCategoryDefaults.maxHours(_category);
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _tensionController.dispose();
    super.dispose();
  }

  void _keepSame() {
    widget.bagBloc.add(RestringRacquet(widget.racquet.id!));
    Navigator.of(context).pop();
  }

  void _submitSpecs() {
    if (!_formKey.currentState!.validate()) return;
    widget.bagBloc.add(
      RestringRacquet(
        widget.racquet.id!,
        keepSame: false,
        materialCategory: _category,
        stringBrand: _brandController.text.trim(),
        stringModel: _modelController.text.trim(),
        tension: double.parse(_tensionController.text.trim()),
        maxRatedHours: _maxHours,
      ),
    );
    Navigator.of(context).pop();
  }

  InputDecoration _decoration(String label) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: CourtMidnightTheme.surfaceElevated,
      labelStyle: GoogleFonts.inter(
        color: CourtMidnightTheme.textSecondary,
        fontSize: 13,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: border(CourtMidnightTheme.surfaceBorder),
      enabledBorder: border(CourtMidnightTheme.surfaceBorder),
      focusedBorder: border(CourtMidnightTheme.primaryVolt, 1.5),
      errorBorder: border(CourtMidnightTheme.healthCritical),
      focusedErrorBorder: border(CourtMidnightTheme.healthCritical, 1.5),
    );
  }

  TextStyle get _fieldStyle => GoogleFonts.inter(
    color: CourtMidnightTheme.textPrimary,
    fontSize: 14,
  );

  String? _requiredValidator(String? value, String message) =>
      value == null || value.trim().isEmpty ? message : null;

  String? _tensionValidator(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    return parsed == null || !parsed.isFinite || parsed <= 0
        ? 'Invalid tension'
        : null;
  }

  Widget _buildSpecsForm() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<StringMaterialCategory>(
              key: RestringSheet.keyCategoryField,
              initialValue: _category,
              dropdownColor: CourtMidnightTheme.surfaceElevated,
              style: _fieldStyle,
              decoration: _decoration('String Material Category'),
              items: [
                for (final category in StringMaterialCategory.values)
                  DropdownMenuItem(
                    value: category,
                    child: Text(category.displayName),
                  ),
              ],
              onChanged: (category) {
                if (category == null || category == _category) return;
                setState(() {
                  _category = category;
                  _maxHours = StringCategoryDefaults.maxHours(category);
                });
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: RestringSheet.keyBrandField,
                    controller: _brandController,
                    textInputAction: TextInputAction.next,
                    style: _fieldStyle,
                    decoration: _decoration('String Brand *'),
                    validator: (v) =>
                        _requiredValidator(v, 'String brand is required'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: RestringSheet.keyModelField,
                    controller: _modelController,
                    textInputAction: TextInputAction.next,
                    style: _fieldStyle,
                    decoration: _decoration('String Model *'),
                    validator: (v) =>
                        _requiredValidator(v, 'String model is required'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: RestringSheet.keyTensionField,
              controller: _tensionController,
              textInputAction: TextInputAction.done,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: _fieldStyle,
              decoration: _decoration('Tension (lbs) *'),
              validator: _tensionValidator,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final racquet = widget.racquet;
    final job = racquet.activeStringJob;
    final currentSetup = [
      if (job?.brand != null && job!.brand!.trim().isNotEmpty)
        job.brand!.trim(),
      if (job?.model != null && job!.model!.trim().isNotEmpty)
        job.model!.trim(),
    ].join(' ');

    return Container(
      key: RestringSheet.keySheet,
      child: AssignmentSheetFrame(
        footer: _isChangingSpecs
            ? Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    key: RestringSheet.keySubmitButton,
                    onPressed: _submitSpecs,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CourtMidnightTheme.primaryVolt,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'RESTRING WITH NEW STRINGS',
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox(height: 16),
        children: [
          Text(
            'RESTRUNG TODAY',
            style: GoogleFonts.barlowCondensed(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: CourtMidnightTheme.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            racquet.name,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CourtMidnightTheme.textPrimary,
            ),
          ),
          if (currentSetup.isNotEmpty)
            Text(
              'Current strings: $currentSetup',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: CourtMidnightTheme.textSecondary,
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              key: RestringSheet.keyKeepSameButton,
              onPressed: _keepSame,
              icon: const Icon(Icons.restart_alt, size: 20),
              label: Text(
                'Keep Same & Reset',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: CourtMidnightTheme.primaryVolt,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: InkWell(
                key: RestringSheet.keyChangeSpecsToggle,
                onTap: () =>
                    setState(() => _isChangingSpecs = !_isChangingSpecs),
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
                        _isChangingSpecs
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 20,
                        color: CourtMidnightTheme.primaryVolt,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Change Specs',
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
          if (_isChangingSpecs) _buildSpecsForm(),
        ],
      ),
    );
  }
}
