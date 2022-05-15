// ignore_for_file: unnecessary_lambdas

import 'package:isolation/isolation.dart';
import 'package:test/test.dart';

void main() {
  group('unit', () {
    test('placeholder', () {
      final connection = Connection.create<int, int, int>(_dublicate, 10);
      expect(connection, isA<Connection>());
      expect(() => connection.add(1), returnsNormally);
      expect(() => connection.addError(Exception()), returnsNormally);
      expect(() => connection.close(), returnsNormally);
    });

    test('dublicate', () {
      final connection = Connection.create<int, int, int>(_dublicate, 10);
      expectLater(
        connection.stream,
        emitsInOrder(
          <Object?>[
            100,
            0,
            0,
            2,
            2,
            4,
            4,
            emitsDone,
          ],
        ),
      );
      connection
        ..add(0)
        ..add(1)
        ..add(2);
      Future.delayed(const Duration(seconds: 1), connection.close);
    });
  });
}

void _dublicate(Connection<int, int> connection, int value) {
  connection.add(value * 10);
  connection.stream.listen((event) {
    connection
      ..add(event * 2)
      ..add(event * 2);
  });
}
