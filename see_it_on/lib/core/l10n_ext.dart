import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

export '../l10n/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

// Kimliklerden (backend kategorisi, asset adı) çevrili metne eşleme.
// Veri listeleri yalnızca kimlik tutar; metin her zaman o anki dilden okunur.

/// 'upper' / 'lower' / 'overall' -> "Üst Giyim" / "Upper wear" ...
String categoryName(AppLocalizations l, String id) => switch (id) {
      'lower' => l.categoryLower,
      'overall' => l.categoryOverall,
      _ => l.categoryUpper,
    };

String categoryHint(AppLocalizations l, String id) => switch (id) {
      'lower' => l.categoryLowerHint,
      'overall' => l.categoryOverallHint,
      _ => l.categoryUpperHint,
    };

/// 'w-m' -> "Kadın M" / "Women M"; 'm-xl' -> "Erkek XL" / "Men XL"
String mannequinName(AppLocalizations l, String id) {
  final parts = id.split('-');
  final size = parts.length > 1 ? parts[1].toUpperCase() : '';
  return parts.first == 'w' ? l.mannequinWomen(size) : l.mannequinMen(size);
}

String garmentName(AppLocalizations l, String id) => switch (id) {
      'blazer' => l.garmentBlazer,
      'shirt-stripe' => l.garmentShirt,
      'hoodie' => l.garmentHoodie,
      'sweater-wave' => l.garmentSweater,
      'turtleneck' => l.garmentTurtleneck,
      'jeans-w' => l.garmentJeans,
      'chino-m' => l.garmentChino,
      'trousers-m' => l.garmentTrousers,
      'skirt-w' => l.garmentSkirt,
      'shorts-w' => l.garmentShorts,
      _ => id,
    };
