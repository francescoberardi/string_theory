import 'package:flutter/material.dart';
import 'package:string_theory_client/string_theory_client.dart';

import '../bloc/bag_bloc.dart';

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
  @override
  Widget build(BuildContext context) {
    // Red-phase stub pending implementation in Story 1.4
    return const SizedBox(
      key: AddRacquetModal.keyModal,
      height: 100,
      child: Center(child: Text('Add Racquet (Stub)')),
    );
  }
}
