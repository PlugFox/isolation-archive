// ignore_for_file: avoid_print

import 'dart:async';

import 'package:isolation/isolation.dart';

void main([List<String>? args]) => runZoned(
      () => Stream<String>.value('ping').isolate(_callback).listen(
            (msg) => print('m> $msg'),
            onError: (Object error, StackTrace stackTrace) =>
                print('m> $error'),
            onDone: () {
              print('m> done');
            },
          ),
      zoneValues: {
        #isolation.log.enabled: true,
      },
    );

Future<void> _callback(Stream<String> stream, EventSink<String> sink) async {
  await stream.forEach((msg) {
    print('s> $msg');
    sink.add('pong');
  });
  await Future<void>.delayed(const Duration(seconds: 3));
}
