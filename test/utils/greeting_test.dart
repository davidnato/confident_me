import 'package:confident_me/core/utils/greeting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('greets by time of day', () {
    expect(buildGreeting(DateTime(2026, 1, 1, 8), ''), 'Good morning');
    expect(buildGreeting(DateTime(2026, 1, 1, 14), ''), 'Good afternoon');
    expect(buildGreeting(DateTime(2026, 1, 1, 20), ''), 'Good evening');
  });

  test('includes a trimmed name when given', () {
    expect(buildGreeting(DateTime(2026, 1, 1, 8), '  Alex '), 'Good morning, Alex');
  });
}
