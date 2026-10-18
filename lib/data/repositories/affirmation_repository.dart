import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/affirmation.dart';

class AffirmationRepository {
  AffirmationRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const assetPath = 'assets/data/affirmations.json';
  final AssetBundle _bundle;

  Future<List<Affirmation>> loadAll() async =>
      parseAffirmations(await _bundle.loadString(assetPath));

  static List<Affirmation> parseAffirmations(String raw) {
    final decoded = jsonDecode(raw);
    final list = decoded is Map<String, dynamic> ? decoded['affirmations'] : decoded;
    if (list is! List) {
      throw const FormatException('affirmations.json has no list.');
    }
    return [
      for (final entry in list)
        if (entry is Map<String, dynamic>)
          if (Affirmation.tryFromJson(entry) case final a?) a,
    ];
  }
}
