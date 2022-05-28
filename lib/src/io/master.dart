import 'dart:async';
import 'dart:isolate';

import 'package:isolation/src/constant.dart';
import 'package:isolation/src/handler.dart';
import 'package:isolation/src/io/channel.dart';
import 'package:isolation/src/io/connection.dart';
import 'package:isolation/src/io/entry_point.dart';
import 'package:isolation/src/io/exception.dart';
import 'package:isolation/src/io/payload.dart';
import 'package:isolation/src/io/service_messages.dart';
import 'package:isolation/src/logging.dart';
import 'package:meta/meta.dart';

/// {@template master_isolate_connection}
/// Isolate helper, that helps to create and manage another isolate.
/// {@endtemplate}
@internal
class MasterIsolateConnection<In, Out> extends IsolateConnection<In, Out> {
  /// {@macro master_isolate_connection}
  MasterIsolateConnection({
    required IsolationHandler<In, Out> handler,
    required EventSink<Out> eventsFromSlave,
  })  : _handler = handler,
        _eventsFromSlave = eventsFromSlave,
        super(
          dataChannel: IsolateChannel<In, Out>(),
          exceptionChannel:
              IsolateChannel<IsolateException, IsolateException>(),
          serviceChannel: IsolateChannel<Object?, Object?>(),
        ) {
    fine('MasterIsolateConnection created');
  }

  /// Slave isolation
  Isolate? _slaveIsolate;

  /// Handler for slave's events
  final EventSink<Out> _eventsFromSlave;

  /// Entry point
  final IsolationHandler<In, Out> _handler;

  StreamSubscription<Out>? _dataSubscription;
  StreamSubscription<IsolateException>? _exceptionSubscription;

  @override
  Future<void> connect() async {
    config('MasterIsolateConnection starts initialization');
    await super.connect();
    // Payload for slave isolate.
    final payload = IsolatePayload<In, Out>(
      dataPort: super.dataChannel.receivePort.sendPort,
      exceptionPort: super.exceptionChannel.receivePort.sendPort,
      servicePort: super.serviceChannel.receivePort.sendPort,
      handler: _handler,
      errorsAreFatal: false,
      enableLogging: Zone.current[kLogEnabled] == true,
    );
    final receiveServicePorts =
        _receiveServicePorts().timeout(const Duration(seconds: 5));
    _slaveIsolate = await Isolate.spawn<IsolatePayload>(
      isolateEntryPoint,
      payload,
      errorsAreFatal: payload.errorsAreFatal,
      onExit: payload.servicePort,
      debugName: Zone.current[kIsolateDebugName]?.toString(),
    ).timeout(const Duration(milliseconds: 30000));
    await receiveServicePorts.timeout(const Duration(milliseconds: 30000));
    _registrateListeners();
  }

  /// Receives service ports from slave isolate and sets them to channels.
  Future<void> _receiveServicePorts() => super.serviceMessages.first.then<void>(
        (msg) {
          if (msg is! IsolateSendPorts) {
            warning(
              'Instead IsolateSendPorts received unexpected message: $msg',
            );
            throw UnsupportedError('Unexpected message');
          }
          super.dataChannel.setPort(msg.dataPort);
          super.exceptionChannel.setPort(msg.exceptionPort);
          super.serviceChannel.setPort(msg.servicePort);
        },
      );

  void _registrateListeners() {
    // Start listening on data channel.
    _dataSubscription = dataChannel.receivePort.cast<Out>().listen(
      _eventsFromSlave.add,
      onError: (Object error, StackTrace stackTrace) {
        warning(
          error,
          stackTrace,
          'MasterIsolateConnection exception on data channel listener',
        );
        _eventsFromSlave.addError(error, stackTrace);
      },
      cancelOnError: false,
    );
    // Start listening on exception channel.
    _exceptionSubscription =
        exceptionChannel.receivePort.cast<IsolateException>().listen(
      (msg) => _eventsFromSlave.addError(msg.exception, msg.stackTrace),
      onError: (Object error, StackTrace stackTrace) {
        warning(
          error,
          stackTrace,
          'MasterIsolateConnection exception on exception channel listener',
        );
        _eventsFromSlave.addError(error, stackTrace);
      },
      cancelOnError: false,
    );
  }

  @override
  void close() {
    try {
      addServiceMessage(null);
      super.close();
      _dataSubscription?.cancel();
      _exceptionSubscription?.cancel();
    } finally {
      _slaveIsolate?.kill();
    }
  }
}
