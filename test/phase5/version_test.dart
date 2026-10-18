import 'dart:io';

import 'package:confident_me/core/constants/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the version shown in About matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)', multiLine: true)
        .firstMatch(pubspec);
    expect(match, isNotNull);
    expect(AppConstants.version, match!.group(1));
  });
}
