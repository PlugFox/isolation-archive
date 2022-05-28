@Timeout(Duration(seconds: 5))
// ignore_for_file: unnecessary_lambdas

import 'package:test/test.dart';

import 'unit/io_test.dart' as io_test;
import 'unit/js_test.dart' as js_test;

void main() {
  group('io', io_test.main);
  group('js', js_test.main);
}
