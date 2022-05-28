import 'dart:async';

import 'package:isolation/isolation.dart';
import 'package:test/test.dart';

void streamTest() {
  group('stream', () {
    Stream<int> source(int count) =>
        Stream<int>.fromIterable(Iterable<int>.generate(count, (i) => i));
    StreamMatcher expected(int count) => emitsInOrder(<Object?>[
          ...Iterable<String>.generate(count, (i) => '* $i'),
          emitsDone,
        ]);

    test('stub', () {
      const count = 10;
      final values = source(count).map<String>((i) => '* $i');
      expectLater(values, expected(count));
    });

    test('emits_in_order', () {
      const count = 10;
      final values = source(count).isolate(_mapInt2StringSync);
      expectLater(values, expected(count));
    });
  });
}

void _mapInt2StringSync(Stream<int> stream, EventSink<String> sink) {
  stream.listen((i) => sink.add('* $i'));
}
