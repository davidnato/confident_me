import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Source of "now". Tests override this so dates are predictable.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
