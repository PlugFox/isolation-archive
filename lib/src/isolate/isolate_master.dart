import 'dart:async';
import 'dart:isolate';

import 'package:isolation/src/connection.dart';
import 'package:isolation/src/connection_exception.dart';
import 'package:isolation/src/connection_status.dart';
import 'package:isolation/src/develop.dart';
import 'package:isolation/src/isolate/isolate_base.dart';
import 'package:isolation/src/isolate/isolate_channel.dart';
import 'package:isolation/src/isolate/isolate_payload.dart';
import 'package:isolation/src/isolate/isolate_service_message.dart';
import 'package:isolation/src/isolate/isolate_slave.dart';

/// {@template isolate_master}
/// Isolate helper, that helps to create and manage another isolate.
/// {@endtemplate}
class IsolateMaster<Send extends Object?, Receive extends Object?,
    Argument extends Object?> extends IsolateBase<Send, Receive> {
  /// {@macro isolate_master}
  static Future<IsolateMaster<Send, Receive, Argument>> spawn<
      Send extends Object?, Receive extends Object?, Argument extends Object?>(
    EntryPoint<Receive, Send, Argument> entryPoint,
    Argument argument, {
    required bool errorsAreFatal,
  }) async {
    final isolate = IsolateMaster<Send, Receive, Argument>(
      entryPoint,
      argument,
      errorsAreFatal: errorsAreFatal,
    );
    await isolate.initConnection();
    config('IsolateMaster spawned');
    return isolate;
  }

  /// {@macro isolate_master}
  IsolateMaster(
    EntryPoint<Receive, Send, Argument> entryPoint,
    Argument argument, {
    required super.errorsAreFatal,
  })  : _entryPoint = entryPoint,
        _argument = argument,
        _sendController = StreamController<Send>(sync: true),
        _receiveController = StreamController<Receive>.broadcast(sync: true),
        super(
          dataChannel: IsolateChannel<Send, Receive>.create(),
          exceptionChannel:
              IsolateChannel<ConnectionException, ConnectionException>.create(),
          serviceChannel: IsolateChannel<IsolateServiceMessage?,
              IsolateServiceMessage?>.create(),
        ) {
    config('IsolateMaster instance created');
  }

  /// Controller for sending data to isolate, public sink
  final StreamController<Send> _sendController;

  /// Controller for public [stream] with data and errors from slave isolate
  final StreamController<Receive> _receiveController;

  final EntryPoint<Receive, Send, Argument> _entryPoint;
  final Argument _argument;
  Isolate? _slaveIsolate;
  StreamSubscription<Send>? _sendSubscription;
  StreamSubscription<Receive>? _dataSubscription;
  StreamSubscription<ConnectionException>? _exceptionSubscription;
  StreamSubscription<IsolateServiceMessage>? _serviceSubscription;

  @override
  Stream<Receive> get stream => _receiveController.stream;

  @override
  Future<void> initConnection() async {
    assert(
      status == ConnectionStatus.initial,
      'IsolateCommunicator is already was initialized.',
    );
    config('IsolateMaster starts initialization');
    try {
      setStatus(ConnectionStatus.initialization);
      // Payload for slave isolate.
      final payload = IsolatePayload<Send, Receive, Argument>(
        dataPort: super.dataChannel.receivePort.sendPort,
        exceptionPort: super.exceptionChannel.receivePort.sendPort,
        servicePort: super.serviceChannel.receivePort.sendPort,
        entryPoint: _entryPoint,
        argument: _argument,
        errorsAreFatal: errorsAreFatal,
      );
      final portsFuture = messages
          .where((msg) => msg is SendPortMessage)
          .cast<SendPortMessage>()
          .first;
      _slaveIsolate = await Isolate.spawn<IsolatePayload>(
        _isolateEntryPoint,
        payload,
        errorsAreFatal: errorsAreFatal,
        onExit: payload.servicePort,
        debugName: Zone.current[#isolation.debugName] as String?,
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
      // Start listening on service channel.
      _serviceSubscription = messages
          .map<IsolateServiceMessage>(
        (Object? msg) =>
            msg == null ? const CloseMessage() : msg as IsolateServiceMessage,
      )
          .listen(
        _onServiceMessage,
        onError: (Object error, StackTrace stackTrace) {
          warning(
            error,
            stackTrace,
            'IsolateMaster exception on service channel listener',
          );
          _receiveController.sink.addError(
            error,
            stackTrace,
          );
        },
        cancelOnError: false,
      );
      // Start listening on data channel.
      _dataSubscription = dataChannel.receivePort.cast<Receive>().listen(
        _receiveController.sink.add,
        onError: (Object error, StackTrace stackTrace) {
          warning(
            error,
            stackTrace,
            'IsolateMaster exception on data channel listener',
          );
          _receiveController.sink.addError(
            error,
            stackTrace,
          );
        },
        cancelOnError: false,
      );
      // Start listening on exception channel.
      _exceptionSubscription =
          exceptionChannel.receivePort.cast<ConnectionException>().listen(
        (msg) {
          print(
            'Get error from isolate to _receiveController "${msg.exception} ${msg.stackTrace}"',
          );
          _receiveController.sink.addError(
            msg.exception,
            msg.stackTrace,
          );
        },
        onError: (Object error, StackTrace stackTrace) {
          print(
            'Get error from isolate to _receiveController',
          );
          warning(
            error,
            stackTrace,
            'IsolateMaster exception on exception channel listener',
          );
          _receiveController.sink.addError(
            error,
            stackTrace,
          );
        },
        cancelOnError: false,
      );
      _sendSubscription = _sendController.stream.listen(
        super.dataChannel.add,
        onError: (Object error, StackTrace stackTrace) {
          super.exceptionChannel.add(
                ConnectionException(error, stackTrace),
              );
        },
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
  Future<void> close() async {
    switch (status) {
      case ConnectionStatus.closing:
        config('IsolateMaster already closing');
        return;
      case ConnectionStatus.closed:
        config('IsolateMaster already closed');
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
    fine('IsolateMaster received service message: $message');
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
        config('IsolateMaster already closing');
        return;
      case ConnectionStatus.closed:
        config('IsolateMaster already closed');
        return;
      default:
        break;
    }
    config('IsolateMaster is closing');
    try {
      fine('IsolateMaster send close service message to slave isolate');
      serviceChannel.add(null);
    } on Object catch (error, stackTrace) {
      severe(
        error,
        stackTrace,
        'IsolateMaster can not send close message to isolate',
      );
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
      _slaveIsolate?.kill();
      setStatus(ConnectionStatus.closed);
    }
  }
} // IsolateMaster

void _isolateEntryPoint(IsolatePayload payload) {
  IsolateSlave? conenction;
  runZonedGuarded<void>(() async {
    info('Execute entry payload in slave isolate');
    conenction = await payload();
  }, (error, stackTrace) {
    severe(error, stackTrace, 'Root exception in slave isolate is catched');
    payload.exceptionPort.send(
      ConnectionException(error, stackTrace),
    );
    print('Add top level error $error to queue');
    if (payload.errorsAreFatal) {
      info('Closing slave isolate after fatal error');
      conenction?.close() ?? Isolate.current.kill();
    }
  });
}
