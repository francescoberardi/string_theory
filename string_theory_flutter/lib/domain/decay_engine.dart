export 'package:string_theory_decay_engine/string_theory_decay_engine.dart';

import 'package:string_theory_client/string_theory_client.dart';
import 'package:string_theory_decay_engine/string_theory_decay_engine.dart';

/// Extension to provide user-friendly display names and defaults for string material categories.
extension StringMaterialCategoryExtension on StringMaterialCategory {
  String get displayName => StringCategoryDefaults.displayName(this);
  double get defaultMaxHours => StringCategoryDefaults.maxHours(this);
  int get shelfLifeDays => StringCategoryDefaults.shelfLifeDays(this);
}
