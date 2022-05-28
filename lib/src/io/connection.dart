import 'dart:async';

import 'package:isolation/src/io/channel.dart';
import 'package:isolation/src/io/exception.dart';
import 'package:meta/meta.dart';

/// {@template isolate_connection}
/// Base class for master and slave isolate connections.
/// {@endtemplate}
@internal
abstract class IsolateConnection<In, Out> implements EventSink<In> {
  /// {@macro isolate_connection}
  IsolateConnection({
    required this.dataChannel,
    required this.exceptionChannel,
    required this.serviceChannel,
  }) : serviceMessages = serviceChannel.receivePort.asBroadcastStream();

  /// Channel for data
  @protected
  @nonVirtual
  final IsolateChannel<In, Out> dataChannel;

  /// Channel for exceptions
  @protected
  @nonVirtual
  final IsolateChannel<IsolateException, IsolateException> exceptionChannel;

  /// Channel for service messages
  @protected
  @nonVirtual
  final IsolateChannel<Object?, Object?> serviceChannel;

  /// Stream of service messages
  @nonVirtual
  final Stream<Object?> serviceMessages;

  bool _isClosed = false;

  /// Establish connection with another isolate
  @mustCallSuper
  Future<void> connect() async {
    assert(!_isClosed, 'IsolateConnection is already closed.');
    if (_isClosed) return;
  }

  @override
  void add(In data) {
    print('IsolateConnection.add($data)');
    assert(!_isClosed, 'IsolateConnection is already closed.');
    if (_isClosed) return;
    dataChannel.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    assert(!_isClosed, 'IsolateConnection is already closed.');
    if (_isClosed) return;
    exceptionChannel.add(IsolateException(error, stackTrace));
  }

  /// Add service message
  void addServiceMessage(Object? message) {
    assert(!_isClosed, 'IsolateConnection is already closed.');
    if (_isClosed) return;
    serviceChannel.add(message);
  }

  @override
  @mustCallSuper
  void close() {
    assert(!_isClosed, 'IsolateConnection is already closed.');
    _isClosed = true;
    dataChannel.close();
    exceptionChannel.close();
    serviceChannel.close();
  }
}
