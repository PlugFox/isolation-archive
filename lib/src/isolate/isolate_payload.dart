import 'dart:async';
import 'dart:isolate';

import 'package:isolation/src/connection.dart' show EntryPoint;
import 'package:isolation/src/connection_exception.dart';
import 'package:isolation/src/isolate/isolate_channel.dart';
import 'package:isolation/src/isolate/isolate_service_message.dart';
import 'package:isolation/src/isolate/isolate_slave.dart';
import 'package:meta/meta.dart';

/// {@template isolate_payload.isolate_payload}
/// IsolatePayload class
/// {@endtemplate}
@internal
@immutable
class IsolatePayload<Send extends Object?, Receive extends Object?,
    Argument extends Object?> {
  /// {@macro isolate_payload.isolate_payload}
  const IsolatePayload({
    required this.dataPort,
    required this.exceptionPort,
    required this.servicePort,
    required this.entryPoint,
    required this.argument,
    required this.errorsAreFatal,
  });

  /// Isolate payload data port
  final SendPort dataPort;

  /// Isolate payload exception port
  final SendPort exceptionPort;

  /// Isolate payload service port
  final SendPort servicePort;

  /// Sets whether uncaught errors will terminate the isolate.
  final bool errorsAreFatal;

  /// Entry point
  final EntryPoint<Receive, Send, Argument> entryPoint;

  /// Arguments
  final Argument argument;

  /// Finish slave isolate initialization
  Future<IsolateSlave<Receive, Send>> call() async {
    // Swaping receive and send generics
    try {
      final connection = IsolateSlave<Receive, Send>(
        dataChannel: IsolateChannel<Receive, Send>.create()..setPort(dataPort),
        exceptionChannel:
            IsolateChannel<ConnectionException, ConnectionException>.create()
              ..setPort(exceptionPort),
        serviceChannel: IsolateChannel<IsolateServiceMessage?,
            IsolateServiceMessage?>.create()
          ..setPort(servicePort),
        errorsAreFatal: errorsAreFatal,
      );
      await connection.initConnection();
      // Workaround to save types between isolates:
      entryPoint(connection, argument);
      return connection;
    } on Object {
      Isolate.current.kill();
      rethrow;
    }
  }
} // IsolatePayload
