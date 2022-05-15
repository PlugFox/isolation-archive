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
  });

  /// Isolate payload data port
  final SendPort dataPort;

  /// Isolate payload exception port
  final SendPort exceptionPort;

  /// Isolate payload service port
  final SendPort servicePort;

  /// Entry point
  final EntryPoint<Receive, Send, Argument> entryPoint;

  /// Arguments
  final Argument argument;

  // TODO: Sets whether uncaught errors will terminate the isolate.
  // Matiunin Mikhail <plugfox@gmail.com>, 15 May 2022
  //bool errorsAreFatal = true

  /// Finish slave isolate initialization
  Future<IsolateSlave<Receive, Send>> call() async {
    // Swaping receive and send generics
    // ignore: close_sinks
    final connection = IsolateSlave<Receive, Send>(
      dataChannel: IsolateChannel<Receive, Send>.create()..setPort(dataPort),
      exceptionChannel:
          IsolateChannel<ConnectionException, ConnectionException>.create()
            ..setPort(exceptionPort),
      serviceChannel:
          IsolateChannel<IsolateServiceMessage, IsolateServiceMessage>.create()
            ..setPort(servicePort),
    );
    await connection.initConnection();
    // Workaround to save types between isolates:
    entryPoint(connection, argument);
    return connection;
  }
} // IsolatePayload
