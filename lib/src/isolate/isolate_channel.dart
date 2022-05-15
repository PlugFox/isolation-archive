import 'dart:isolate';

import 'package:meta/meta.dart';

/// {@template isolate_channel.isolate_channel}
/// Channel between two isolates.
/// Used to send data, exception or service messages between isolates.
/// {@endtemplate}
@internal
class IsolateChannel<Send extends Object?, Receive extends Object?>
    extends Sink<Send> {
  /// {@macro isolate_channel.isolate_channel}
  IsolateChannel.create() : receivePort = ReceivePort();

  /// Isolate channel receive port already closed;
  bool get isClosed => _isClosed;
  bool _isClosed = false;

  /// Contain [SendPort]
  bool get hasSendPort => _sendPort != null;

  /// Allow receiving data from the isolate.
  final ReceivePort receivePort;

  /// Allow sending data to another isolate.
  SendPort? _sendPort;

  @override
  void add(Send data) {
    assert(
      hasSendPort,
      'IsolateChannel is not connected to another isolate.',
    );
    _sendPort?.send(data);
  }

  /// Set new send port
  // ignore: use_setters_to_change_properties
  void setPort(SendPort sendPort) => _sendPort = sendPort;

  @override
  void close() {
    if (isClosed) return;
    receivePort.close();
    _isClosed = true;
  }
}
