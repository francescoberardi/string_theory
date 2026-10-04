import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:string_theory_client/string_theory_client.dart';

import '../bloc/bag_bloc.dart';
import '../theme/court_midnight_theme.dart';

/// Extension to provide user-friendly display names for string material categories.
extension StringMaterialCategoryExtension on StringMaterialCategory {
  String get displayName {
    switch (this) {
      case StringMaterialCategory.coPoly:
        return 'Co-Polyester';
      case StringMaterialCategory.multifilament:
        return 'Multifilament';
      case StringMaterialCategory.syntheticGut:
        return 'Synthetic Gut';
      case StringMaterialCategory.naturalGut:
        return 'Natural Gut';
      case StringMaterialCategory.kevlar:
        return 'Kevlar';
      case StringMaterialCategory.hybrid:
        return 'Hybrid';
      case StringMaterialCategory.other:
        return 'Other';
    }
  }
}

/// Preset racquet and string bed configuration for 1-tap setup.
class RacquetPreset {
  final String name;
  final String? brand;
  final String? model;
  final StringMaterialCategory materialCategory;
  final String stringBrand;
  final String stringModel;
  final double tension;
  final double maxRatedHours;

  const RacquetPreset({
    required this.name,
    this.brand,
    this.model,
    required this.materialCategory,
    required this.stringBrand,
    required this.stringModel,
    required this.tension,
    required this.maxRatedHours,
  });

  /// Popular Poly preset: Babolat RPM Blast @ 52 lbs on Babolat Pure Aero
  static const popularPoly = RacquetPreset(
    name: 'Babolat Pure Aero',
    brand: 'Babolat',
    model: 'Pure Aero',
    materialCategory: StringMaterialCategory.coPoly,
    stringBrand: 'Babolat',
    stringModel: 'RPM Blast',
    tension: 52.0,
    maxRatedHours: 20.0,
  );
}

/// Helper mapping string categories to manufacturer max play hour defaults.
class StringCategoryDefaults {
  /// Returns smart default play hours for a given string material category.
  static double maxHours(StringMaterialCategory category) {
    switch (category) {
      case StringMaterialCategory.coPoly:
        return 20.0;
      case StringMaterialCategory.multifilament:
        return 35.0;
      case StringMaterialCategory.syntheticGut:
        return 30.0;
      case StringMaterialCategory.naturalGut:
        return 50.0;
      case StringMaterialCategory.kevlar:
        return 25.0;
      case StringMaterialCategory.hybrid:
        return 25.0;
      case StringMaterialCategory.other:
        return 20.0;
    }
  }
}

/// Modal bottom sheet / dialog form for adding a new racquet to the virtual bag (Story 1.4).
class AddRacquetModal extends StatefulWidget {
  final BagBloc? bagBloc;

  const AddRacquetModal({super.key, this.bagBloc});

  static const keyModal = Key('add_racquet_modal');
  static const keyNameField = Key('add_racquet_name_field');
  static const keyBrandField = Key('add_racquet_brand_field');
  static const keyModelField = Key('add_racquet_model_field');
  static const keyCategoryField = Key('add_racquet_category_field');
  static const keyStringBrandField = Key('add_racquet_string_brand_field');
  static const keyStringModelField = Key('add_racquet_string_model_field');
  static const keyTensionField = Key('add_racquet_tension_field');
  static const keyMaxHoursField = Key('add_racquet_max_hours_field');
  static const keyDateField = Key('add_racquet_date_field');
  static const keyPrimarySwitch = Key('add_racquet_primary_switch');
  static const keyPresetRpmBlast = Key('add_racquet_preset_rpm_blast');
  static const keySubmitButton = Key('add_racquet_submit_button');

  /// Displays the AddRacquetModal as a responsive modal bottom sheet.
  static Future<void> show(BuildContext context, {BagBloc? bagBloc}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddRacquetModal(bagBloc: bagBloc),
    );
  }

  @override
  State<AddRacquetModal> createState() => _AddRacquetModalState();
}

class _AddRacquetModalState extends State<AddRacquetModal> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _stringBrandController;
  late final TextEditingController _stringModelController;
  late final TextEditingController _tensionController;
  late final TextEditingController _maxHoursController;
  late final TextEditingController _dateController;

  StringMaterialCategory? _selectedCategory;
  DateTime _stringingDate = DateTime.now();
  bool _isPrimary = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _brandController = TextEditingController();
    _modelController = TextEditingController();
    _stringBrandController = TextEditingController();
    _stringModelController = TextEditingController();
    _tensionController = TextEditingController();
    _maxHoursController = TextEditingController();
    _dateController = TextEditingController(text: _formatDate(_stringingDate));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _stringBrandController.dispose();
    _stringModelController.dispose();
    _tensionController.dispose();
    _maxHoursController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _applyPreset(RacquetPreset preset) {
    setState(() {
      _nameController.text = preset.name;
      _brandController.text = preset.brand ?? '';
      _modelController.text = preset.model ?? '';
      _selectedCategory = preset.materialCategory;
      _stringBrandController.text = preset.stringBrand;
      _stringModelController.text = preset.stringModel;
      _tensionController.text = preset.tension.toStringAsFixed(1);
      _maxHoursController.text = preset.maxRatedHours.toStringAsFixed(1);
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _stringingDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: CourtMidnightTheme.primaryVolt,
              onPrimary: Colors.black,
              surface: CourtMidnightTheme.surfaceElevated,
              onSurface: CourtMidnightTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _stringingDate = picked;
        _dateController.text = _formatDate(picked);
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final tension = double.tryParse(_tensionController.text.trim()) ?? 52.0;
    final maxHours = double.tryParse(_maxHoursController.text.trim()) ?? 20.0;

    final event = AddRacquet(
      name: _nameController.text.trim(),
      brand: _brandController.text.trim().isEmpty
          ? null
          : _brandController.text.trim(),
      model: _modelController.text.trim().isEmpty
          ? null
          : _modelController.text.trim(),
      isPrimary: _isPrimary,
      materialCategory: _selectedCategory ?? StringMaterialCategory.coPoly,
      stringBrand: _stringBrandController.text.trim(),
      stringModel: _stringModelController.text.trim(),
      tension: tension,
      maxRatedHours: maxHours,
      stringingDate: _stringingDate,
    );

    final bloc = widget.bagBloc ?? context.read<BagBloc>();
    bloc.add(event);

    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  InputDecoration _inputDecoration({
    required String labelText,
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: CourtMidnightTheme.surfaceElevated,
      labelStyle: GoogleFonts.inter(
        color: CourtMidnightTheme.textSecondary,
        fontSize: 13,
      ),
      hintStyle: GoogleFonts.inter(
        color: CourtMidnightTheme.textTertiary,
        fontSize: 13,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CourtMidnightTheme.surfaceBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CourtMidnightTheme.surfaceBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: CourtMidnightTheme.primaryVolt,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CourtMidnightTheme.healthCritical),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: CourtMidnightTheme.healthCritical,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: AddRacquetModal.keyModal,
      decoration: const BoxDecoration(
        color: CourtMidnightTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        border: Border(
          top: BorderSide(color: CourtMidnightTheme.surfaceBorder, width: 1),
          left: BorderSide(color: CourtMidnightTheme.surfaceBorder, width: 1),
          right: BorderSide(color: CourtMidnightTheme.surfaceBorder, width: 1),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top drag handle
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

                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ADD NEW RACQUET',
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: CourtMidnightTheme.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: CourtMidnightTheme.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 1-Tap Preset Button
                OutlinedButton.icon(
                  key: AddRacquetModal.keyPresetRpmBlast,
                  onPressed: () => _applyPreset(RacquetPreset.popularPoly),
                  icon: const Icon(
                    Icons.bolt,
                    color: CourtMidnightTheme.primaryVolt,
                    size: 18,
                  ),
                  label: Text(
                    'Popular Poly: Babolat RPM Blast @ 52 lbs',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CourtMidnightTheme.primaryVolt,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    side: const BorderSide(
                      color: CourtMidnightTheme.primaryMuted,
                      width: 1,
                    ),
                    backgroundColor: CourtMidnightTheme.surfaceElevated,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Racquet Frame Inputs
                TextFormField(
                  key: AddRacquetModal.keyNameField,
                  controller: _nameController,
                  style: GoogleFonts.inter(
                    color: CourtMidnightTheme.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: _inputDecoration(
                    labelText: 'Racquet Nickname / Frame *',
                    hintText: 'e.g. Babolat Pure Aero',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Racquet name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: AddRacquetModal.keyBrandField,
                        controller: _brandController,
                        style: GoogleFonts.inter(
                          color: CourtMidnightTheme.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: _inputDecoration(
                          labelText: 'Brand (optional)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: AddRacquetModal.keyModelField,
                        controller: _modelController,
                        style: GoogleFonts.inter(
                          color: CourtMidnightTheme.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: _inputDecoration(
                          labelText: 'Model (optional)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // String Material Category Dropdown
                DropdownButtonFormField<StringMaterialCategory>(
                  key: AddRacquetModal.keyCategoryField,
                  initialValue: _selectedCategory,
                  dropdownColor: CourtMidnightTheme.surfaceElevated,
                  style: GoogleFonts.inter(
                    color: CourtMidnightTheme.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: _inputDecoration(
                    labelText: 'String Material Category *',
                  ),
                  items: StringMaterialCategory.values.map((cat) {
                    return DropdownMenuItem<StringMaterialCategory>(
                      value: cat,
                      child: Text(cat.displayName),
                    );
                  }).toList(),
                  onChanged: (cat) {
                    if (cat == null) return;
                    setState(() {
                      _selectedCategory = cat;
                      _maxHoursController.text =
                          StringCategoryDefaults.maxHours(
                            cat,
                          ).toStringAsFixed(1);
                    });
                  },
                  validator: (val) {
                    if (val == null) {
                      return 'Please select a material category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // String Brand & Model Inputs
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: AddRacquetModal.keyStringBrandField,
                        controller: _stringBrandController,
                        style: GoogleFonts.inter(
                          color: CourtMidnightTheme.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: _inputDecoration(
                          labelText: 'String Brand *',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'String brand is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: AddRacquetModal.keyStringModelField,
                        controller: _stringModelController,
                        style: GoogleFonts.inter(
                          color: CourtMidnightTheme.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: _inputDecoration(
                          labelText: 'String Model *',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'String model is required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Tension & Max Hours Inputs
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: AddRacquetModal.keyTensionField,
                        controller: _tensionController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: GoogleFonts.inter(
                          color: CourtMidnightTheme.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: _inputDecoration(
                          labelText: 'Tension (lbs) *',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Tension is required';
                          }
                          final parsed = double.tryParse(val.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Invalid tension';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: AddRacquetModal.keyMaxHoursField,
                        controller: _maxHoursController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: GoogleFonts.inter(
                          color: CourtMidnightTheme.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: _inputDecoration(
                          labelText: 'Max Rated Hours *',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Max hours is required';
                          }
                          final parsed = double.tryParse(val.trim());
                          if (parsed == null || parsed <= 0) {
                            return 'Invalid max hours';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Stringing Date & Primary Switch
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: AddRacquetModal.keyDateField,
                        controller: _dateController,
                        readOnly: true,
                        onTap: _selectDate,
                        style: GoogleFonts.inter(
                          color: CourtMidnightTheme.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: _inputDecoration(
                          labelText: 'Stringing Date',
                          suffixIcon: const Icon(
                            Icons.calendar_today,
                            color: CourtMidnightTheme.textSecondary,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Primary',
                            style: GoogleFonts.inter(
                              color: CourtMidnightTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Switch(
                            key: AddRacquetModal.keyPrimarySwitch,
                            value: _isPrimary,
                            activeThumbColor: CourtMidnightTheme.primaryVolt,
                            onChanged: (val) =>
                                setState(() => _isPrimary = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Submit CTA Button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    key: AddRacquetModal.keySubmitButton,
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CourtMidnightTheme.primaryVolt,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'ADD RACQUET TO BAG',
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
