import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:isolation/isolation.dart';

import '../src/event/event.dart';

@pragma('vm:entry-point')
void main([List<String>? args]) => runZonedGuarded<Future<void>>(
      () async {
        log('[master] Run isolate and pass ref to File with raw JSON as argument');
        final connection = await Connection.spawn<Object, Event, File>(
          _entryPoint,
          File('assets/large-file.json'),
          errorsAreFatal: true,
        );
        log('[master] Start listening to events');
        await Future<void>.delayed(const Duration(seconds: 2));
        var count = 0;
        final completer = Completer<void>();
        final subscribtion =
            connection.stream.map<String>((event) => event.toString()).listen(
          (event) {
            count++;
          },
          onError: (Object error, StackTrace stackTrace) {
            print('Get error from isolate');
            print('1');
            log('[master] Error in isolate: $error');
            completer.completeError(error, stackTrace);
          },
          onDone: () {
            print('2');
            if (!completer.isCompleted) {
              completer.complete();
            }
          },
        );
        await completer.future.then(
          (value) {
            print('good');
          },
          onError: (Object e, StackTrace st) {
            print('bad');
          },
        );
        await subscribtion.cancel();
        print('[master] Successful read $count events');
        // ...
        log('[master] Closing connection');
        await Future<void>.delayed(const Duration(seconds: 2)).then((_) {
          connection.close();
        });
        //exit(0);
      },
      (error, stackTrace) {
        log(
          '[master] Fatal error: $error\n$stackTrace',
          error: error,
          level: 2000,
          stackTrace: stackTrace,
        );
        //exit(2);
      },
      zoneValues: <Symbol, Object>{
        #isolation.log: false,
        #isolation.debugName: 'json_decoder_isolate',
      },
    );

void _entryPoint(Connection<Event, Object> connection, File file) =>
    Future<void>(() async {
      log('[slave] Isoalte is running and starting to parse JSON');
      try {
        connection.addError(Exception('add sample error'));
        await Future<void>.delayed(const Duration(seconds: 1));
        final rawJson = await file.readAsString();
        final json = (jsonDecode(rawJson) as Iterable<Object?>)
            .cast<Map<String, Object?>>()
            .toList(growable: false);
        log('[slave] JSON contains ${json.length} events');
        var count = 0;
        for (final item in json) {
          final event = Event.fromJson(item);
          connection.add(event);
          count++;
        }
        log('[slave] Successfully send all $count events');
        //throw Exception('Sample exceptions');
      } on Object catch (exception) {
        log('[slave] Error in isolate: $exception');
        rethrow;
      } finally {
        log('[slave] Finished parsing JSON and now closing isolate connection');
        // TODO: remove Future.delayed
        // Matiunin Mikhail <plugfox@gmail.com>, 28 May 2022
        await Future.delayed(const Duration(seconds: 1), () {
          connection.close();
        });
        log('[slave] Isoalte is closing after processing');
      }
    });
