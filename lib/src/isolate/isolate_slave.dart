import 'dart:async';
import 'dart:isolate';

import 'package:isolation/src/connection_exception.dart';
import 'package:isolation/src/connection_status.dart';
import 'package:isolation/src/develop.dart';
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
    required super.errorsAreFatal,
  })  : _sendController = StreamController<Send>(sync: true),
        _receiveController = StreamController<Receive>.broadcast(sync: true) {
    fine('IsolateSlave created');
  }

  /// Controller for sending data to isolate, public sink
  final StreamController<Send> _sendController;

  /// Controller for public [stream] with data and errors from slave isolate
  final StreamController<Receive> _receiveController;

  StreamSubscription<Send>? _sendSubscription;
  StreamSubscription<Receive>? _dataSubscription;
  StreamSubscription<ConnectionException>? _exceptionSubscription;
  StreamSubscription<IsolateServiceMessage>? _serviceSubscription;

  @override
  Stream<Receive> get stream => _receiveController.stream;

  @override
  Future<void> initConnection() async {
    fine('IsolateSlave initConnection');
    assert(
      status == ConnectionStatus.initial,
      'IsolateCommunicator is already was initialized.',
    );
    try {
      setStatus(ConnectionStatus.initialization);
      fine('IsolateSlave initialization is started');
      super.serviceChannel.add(
            SendPortMessage(
              dataPort: super.dataChannel.receivePort.sendPort,
              exceptionPort: super.exceptionChannel.receivePort.sendPort,
              servicePort: super.serviceChannel.receivePort.sendPort,
            ),
          );
      fine('IsolateSlave start listening on service channel');
      _serviceSubscription = messages
          .map<IsolateServiceMessage>(
        (Object? msg) =>
            msg == null ? const CloseMessage() : msg as IsolateServiceMessage,
      )
          .listen(
        _onServiceMessage,
        onError: (Object error, StackTrace stackTrace) {
          print('!!!!!!!!!!!!!!!!!');
          warning(
            error,
            stackTrace,
            'IsolateSlave exception on service channel listener',
          );
          _sendController.sink.addError(
            error,
            stackTrace,
          );
        },
        cancelOnError: false,
      );
      fine('IsolateSlave start listening on data channel');
      _dataSubscription = dataChannel.receivePort.cast<Receive>().listen(
        _receiveController.sink.add,
        onError: (Object error, StackTrace stackTrace) {
          print('!!!!!!!!!!!!!!!!!');
          warning(
            error,
            stackTrace,
            'IsolateSlave exception on data channel listener',
          );
          _sendController.sink.addError(
            error,
            stackTrace,
          );
        },
        cancelOnError: false,
      );
      fine('IsolateSlave start listening on exception channel');
      _exceptionSubscription =
          exceptionChannel.receivePort.cast<ConnectionException>().listen(
        (msg) => _receiveController.sink.addError(
          msg.exception,
          msg.stackTrace,
        ),
        onError: (Object error, StackTrace stackTrace) {
          warning(
            error,
            stackTrace,
            'IsolateSlave exception on exception channel listener',
          );
          _sendController.sink.addError(
            error,
            stackTrace,
          );
        },
        cancelOnError: false,
      );
      fine('IsolateSlave start listening send controller');
      _sendSubscription = _sendController.stream.listen(
        super.dataChannel.add,
        onError: (Object error, StackTrace stackTrace) =>
            super.exceptionChannel.add(
                  ConnectionException(error, stackTrace),
                ),
        cancelOnError: false,
      );
      setStatus(ConnectionStatus.established);
      info('IsolateSlave connection is established');
    } on Object catch (error, stackTrace) {
      setStatus(ConnectionStatus.error);
      severe(
        error,
        stackTrace,
        'IsolateSlave exception during connection initialization',
      );
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
  Future<void> close() async {
    switch (status) {
      case ConnectionStatus.closing:
        config('IsolateSlave already closing');
        return;
      case ConnectionStatus.closed:
        config('IsolateSlave already closed');
        return;
      default:
        break;
    }
    super.onInitConnection(() async {
      assert(
        status == ConnectionStatus.established,
        'Not connected to another isolate right now',
      );
      await _forceClose();
    });
  }

  void _onServiceMessage(IsolateServiceMessage message) {
    fine('Received service message: $message');
    message.map<void>(
      sendPort: (msg) {},
      handshakeCompleted: (msg) {},
      ping: (msg) {},
      pong: (msg) {},
      close: (msg) {
        switch (status) {
          case ConnectionStatus.initial:
          case ConnectionStatus.established:
          case ConnectionStatus.initialization:
          case ConnectionStatus.error:
            close();
            break;
          case ConnectionStatus.closing:
          case ConnectionStatus.closed:
            break;
        }
      },
    );
  }

  Future<void> _forceClose() async {
    switch (status) {
      case ConnectionStatus.closing:
        config('IsolateSlave already closing');
        return;
      case ConnectionStatus.closed:
        config('IsolateSlave already closed');
        return;
      default:
        break;
    }
    config('IsolateSlave is closing');
    try {
      fine('IsolateMaster send close service message to slave isolate');
      serviceChannel.add(null);
    } on Object catch (error, stackTrace) {
      severe(error, stackTrace, 'Can not send close message to isolate');
    }
    try {
      setStatus(ConnectionStatus.closing);
      await _sendSubscription?.cancel();
      await _dataSubscription?.cancel();
      await _exceptionSubscription?.cancel();
      await _serviceSubscription?.cancel();
      await _sendController.close();
      dataChannel.close();
      exceptionChannel.close();
      serviceChannel.close();
      await _receiveController.close();
    } on Object catch (error, stackTrace) {
      severe(error, stackTrace);
      rethrow;
    } finally {
      Isolate.current.kill();
      setStatus(ConnectionStatus.closed);
      info('IsolateSlave is closed');
    }
  }
}
