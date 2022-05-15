import 'dart:async';
import 'dart:isolate';

import 'package:isolation/src/connection.dart';
import 'package:isolation/src/connection_exception.dart';
import 'package:isolation/src/connection_status.dart';
import 'package:isolation/src/isolate/isolate_base.dart';
import 'package:isolation/src/isolate/isolate_channel.dart';
import 'package:isolation/src/isolate/isolate_payload.dart';
import 'package:isolation/src/isolate/isolate_service_message.dart';

/// {@template isolate_master}
/// Isolate helper, that helps to create and manage another isolate.
/// {@endtemplate}
class IsolateMaster<Send extends Object?, Receive extends Object?,
    Argument extends Object?> extends IsolateBase<Send, Receive> {
  /// {@macro isolate_master}
  static Future<IsolateMaster<Send, Receive, Argument>> spawn<
      Send extends Object?, Receive extends Object?, Argument extends Object?>(
    EntryPoint<Receive, Send, Argument> entryPoint,
    Argument argument,
  ) async {
    final isolate =
        IsolateMaster<Send, Receive, Argument>(entryPoint, argument);
    await isolate.initConnection();
    return isolate;
  }

  /// {@macro isolate_master}
  IsolateMaster(
    EntryPoint<Receive, Send, Argument> entryPoint,
    Argument argument,
  )   : _entryPoint = entryPoint,
        _argument = argument,
        _sendController = StreamController<Send>(sync: true),
        _receiveController = StreamController<Receive>.broadcast(sync: true),
        super(
          dataChannel: IsolateChannel<Send, Receive>.create(),
          exceptionChannel:
              IsolateChannel<ConnectionException, ConnectionException>.create(),
          serviceChannel: IsolateChannel<IsolateServiceMessage,
              IsolateServiceMessage>.create(),
        );

  final StreamController<Send> _sendController;
  final StreamController<Receive> _receiveController;
  final EntryPoint<Receive, Send, Argument> _entryPoint;
  final Argument _argument;
  Isolate? _slaveIsolate;
  StreamSubscription<Send>? _sendSubscription;
  StreamSubscription<Receive>? _dataSubscription;
  StreamSubscription<ConnectionException>? _exceptionSubscription;

  @override
  Stream<Receive> get stream => _receiveController.stream;

  @override
  Future<void> initConnection() async {
    assert(
      status == ConnectionStatus.initial,
      'IsolateCommunicator is already was initialized.',
    );
    try {
      setStatus(ConnectionStatus.initialization);
      final payload = IsolatePayload<Send, Receive, Argument>(
        dataPort: super.dataChannel.receivePort.sendPort,
        exceptionPort: super.exceptionChannel.receivePort.sendPort,
        servicePort: super.serviceChannel.receivePort.sendPort,
        entryPoint: _entryPoint,
        argument: _argument,
      );
      final portsFuture = messages
          .where((msg) => msg is SendPortMessage)
          .cast<SendPortMessage>()
          .first;
      _slaveIsolate = await Isolate.spawn<IsolatePayload>(
        _isolateEntryPoint,
        payload,
      ).timeout(const Duration(milliseconds: 30000));
      final ports =
          await portsFuture.timeout(const Duration(milliseconds: 30000));
      dataChannel.setPort(ports.dataPort);
      exceptionChannel.setPort(ports.exceptionPort);
      serviceChannel.setPort(ports.servicePort);
      super.serviceChannel.add(
            HandshakeCompletedMessage(
              dataPort: ports.dataPort,
              exceptionPort: ports.exceptionPort,
              servicePort: ports.servicePort,
            ),
          );
      _dataSubscription = dataChannel.receivePort.cast<Receive>().listen(
            _receiveController.sink.add,
            cancelOnError: false,
          );
      _exceptionSubscription =
          exceptionChannel.receivePort.cast<ConnectionException>().listen(
                (msg) => _receiveController.sink.addError(
                  msg.exception,
                  msg.stackTrace,
                ),
                cancelOnError: false,
              );
      _sendSubscription = _sendController.stream.listen(
        super.dataChannel.add,
        onError: (Object error, StackTrace stackTrace) =>
            super.exceptionChannel.add(
                  ConnectionException(error, stackTrace),
                ),
        cancelOnError: false,
      );
      setStatus(ConnectionStatus.established);
    } on Object catch (error, stackTrace) {
      setStatus(ConnectionStatus.error);
      _receiveController.addError(error, stackTrace);
      await _forceClose();
      rethrow;
    }
  }

  @override
  void add(Send data) =>
      super.onInitConnection(() => _sendController.add(data));

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      super.onInitConnection(() => _sendController.addError(error, stackTrace));

  @override
  Future<void> close() => Future<void>.value(
        super.onInitConnection(() async {
          assert(
            status == ConnectionStatus.established,
            'Not connected to another isolate right now',
          );
          await _forceClose();
        }),
      );

  Future<void> _forceClose() async {
    try {
      setStatus(ConnectionStatus.closing);
      // TODO: send service data close
      await _sendSubscription?.cancel();
      await _dataSubscription?.cancel();
      await _exceptionSubscription?.cancel();
      await _sendController.close();
      dataChannel.close();
      exceptionChannel.close();
      serviceChannel.close();
      await _receiveController.close();
      setStatus(ConnectionStatus.closed);
    } on Object {
      rethrow;
    } finally {
      _slaveIsolate?.kill();
    }
  }
} // IsolateMaster

void _isolateEntryPoint(IsolatePayload payload) =>
    runZonedGuarded<void>(() async {
      // ignore: close_sinks
      final connection = await payload();
    }, (error, stackTrace) {
      payload.exceptionPort.send(
        ConnectionException(error, stackTrace),
      );
      // TODO: bool errorsAreFatal = true
      // Matiunin Mikhail <plugfox@gmail.com>, 15 May 2022
    });
