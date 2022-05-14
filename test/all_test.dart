// ignore_for_file: unnecessary_lambdas

import 'package:isolation/isolation.dart';
import 'package:test/test.dart';

void main() {
  group('unit', () {
    test('placeholder', () {
      expect(() => Isolation(), returnsNormally);
      expect(Isolation<int>(), isA<Isolation<num>>());
      expect(() => Isolation<int>().add(1), returnsNormally);
      expect(() => Isolation<int>().addError(Exception()), returnsNormally);
      expect(() => Isolation<int>().close(), returnsNormally);
    });
  });
}
