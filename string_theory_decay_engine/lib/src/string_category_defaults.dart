/// Canonical tennis string material categories within the domain layer.
enum DomainStringMaterialCategory {
  coPoly,
  multifilament,
  syntheticGut,
  naturalGut,
  kevlar,
  hybrid,
  other;

  static final Map<String, DomainStringMaterialCategory> _nameMap =
      DomainStringMaterialCategory.values.asNameMap();

  /// Resolves any Dart [Enum] (e.g. from server or client generated protocol)
  /// to a canonical [DomainStringMaterialCategory].
  ///
  /// Falls back to [DomainStringMaterialCategory.other] for unrecognized enums.
  static DomainStringMaterialCategory fromEnum(Enum category) =>
      _nameMap[category.name] ?? DomainStringMaterialCategory.other;

  /// Default shelf life in calendar days.
  int get shelfLifeDays => StringCategoryDefaults.shelfLifeDays(this);

  /// Default manufacturer recommended maximum court play hours.
  double get defaultMaxHours => StringCategoryDefaults.maxHours(this);

  /// Formatted display name.
  String get displayName => StringCategoryDefaults.displayName(this);
}

/// Centralized decay rules and smart defaults for tennis string material categories.
///
/// Accepts polymorphic [Enum] inputs to seamlessly support Serverpod server models,
/// client protocol models, and pure domain enums.
class StringCategoryDefaults {
  /// Default shelf life in days per string material category.
  static int shelfLifeDays(Enum category) {
    switch (DomainStringMaterialCategory.fromEnum(category)) {
      case DomainStringMaterialCategory.coPoly:
        return 75;
      case DomainStringMaterialCategory.multifilament:
      case DomainStringMaterialCategory.syntheticGut:
        return 180;
      case DomainStringMaterialCategory.naturalGut:
        return 365;
      case DomainStringMaterialCategory.kevlar:
        return 120;
      case DomainStringMaterialCategory.hybrid:
      case DomainStringMaterialCategory.other:
        return 180;
    }
  }

  /// Default manufacturer recommended maximum court hours per string category.
  static double maxHours(Enum category) {
    switch (DomainStringMaterialCategory.fromEnum(category)) {
      case DomainStringMaterialCategory.coPoly:
        return 20.0;
      case DomainStringMaterialCategory.multifilament:
        return 35.0;
      case DomainStringMaterialCategory.syntheticGut:
        return 30.0;
      case DomainStringMaterialCategory.naturalGut:
        return 50.0;
      case DomainStringMaterialCategory.kevlar:
        return 25.0;
      case DomainStringMaterialCategory.hybrid:
        return 25.0;
      case DomainStringMaterialCategory.other:
        return 20.0;
    }
  }

  /// User-friendly display names for string material categories.
  static String displayName(Enum category) {
    switch (DomainStringMaterialCategory.fromEnum(category)) {
      case DomainStringMaterialCategory.coPoly:
        return 'Co-Polyester';
      case DomainStringMaterialCategory.multifilament:
        return 'Multifilament';
      case DomainStringMaterialCategory.syntheticGut:
        return 'Synthetic Gut';
      case DomainStringMaterialCategory.naturalGut:
        return 'Natural Gut';
      case DomainStringMaterialCategory.kevlar:
        return 'Kevlar';
      case DomainStringMaterialCategory.hybrid:
        return 'Hybrid';
      case DomainStringMaterialCategory.other:
        return 'Other';
    }
  }
}
