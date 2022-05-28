import 'dart:async';
import 'dart:isolate';

import 'package:isolation/src/handler.dart';
import 'package:isolation/src/io/slave.dart';
import 'package:meta/meta.dart';

/// {@template isolate_payload}
/// IsolatePayload class
/// {@endtemplate}
@internal
@immutable
class IsolatePayload<In, Out> {
  /// {@macro isolate_payload}
  const IsolatePayload({
    required this.dataPort,
    required this.exceptionPort,
    required this.servicePort,
    required this.handler,
    required this.enableLogging,
    required this.errorsAreFatal,
  });

  /// Isolate payload data port
  final SendPort dataPort;

  /// Isolate payload exception port
  final SendPort exceptionPort;

  /// Isolate payload service port
  final SendPort servicePort;

  /// Handler
  final IsolationHandler<In, Out> handler;

  /// Enable logging
  final bool enableLogging;

  /// Sets whether uncaught errors will terminate the isolate.
  final bool errorsAreFatal;

  /// Finish slave isolate initialization
  Future<SlaveIsolateConnection<Out, In>> call() async {
    try {
      // Swaping receive and send generics
      final connection = SlaveIsolateConnection<Out, In>(
        dataSendPort: dataPort,
        exceptiondataSendPort: exceptionPort,
        servicedataSendPort: servicePort,
      );
      await connection.connect();
      // Workaround to save types between isolates:
      handler(connection.stream, connection.sink);
      return connection;
    } on Object {
      rethrow;
    }
  }
} // IsolatePayload
