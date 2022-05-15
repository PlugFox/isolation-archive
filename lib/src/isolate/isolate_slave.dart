import 'dart:async';
import 'dart:isolate';

import 'package:isolation/src/connection_exception.dart';
import 'package:isolation/src/connection_status.dart';
import 'package:isolation/src/isolate/isolate_base.dart';
import 'package:isolation/src/isolate/isolate_service_message.dart';

/// {@template isolate_slave}
/// Isolate helper, that helps to create and manage another isolate.
/// {@endtemplate}
class IsolateSlave<Send extends Object?, Receive extends Object?>
    extends IsolateBase<Send, Receive> {
  /// {@macro isolate_slave}
  IsolateSlave({
    required super.dataChannel,
    required super.exceptionChannel,
    required super.serviceChannel,
  })  : _sendController = StreamController<Send>(sync: true),
        _receiveController = StreamController<Receive>.broadcast(sync: true);

  final StreamController<Send> _sendController;
  final StreamController<Receive> _receiveController;
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
      super.serviceChannel.add(
            SendPortMessage(
              dataPort: super.dataChannel.receivePort.sendPort,
              exceptionPort: super.exceptionChannel.receivePort.sendPort,
              servicePort: super.serviceChannel.receivePort.sendPort,
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
      Isolate.current.kill();
    }
  }
}
