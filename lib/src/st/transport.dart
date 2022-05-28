import 'dart:async';

import 'package:isolation/src/handler.dart';
import 'package:isolation/src/transport.dart';
import 'package:meta/meta.dart';

/// Create stub transport.
/// {@nodoc}
@internal
Transport<In, Out> createTransport<In, Out>(
  IsolationHandler<In, Out> handler,
  EventSink<Out> output,
) =>
    StubTransport<In, Out>(handler, output);

/// Stub transport
@internal
class StubTransport<In, Out> implements Transport<In, Out> {
  /// Stub transport
  StubTransport(IsolationHandler<In, Out> handler, EventSink<Out> output)
      : _outSink = output,
        _handler = handler;
  final Completer<void> _initializationCompleter = Completer<void>();
  final StreamController<In> _inController = StreamController<In>();
  final EventSink<Out> _outSink;
  final IsolationHandler<In, Out> _handler;

  bool _inProgress = false;

  @override
  bool get isInitialized => _initializationCompleter.isCompleted;

  @override
  FutureOr<void> initialize() {
    if (isInitialized) return null;
    if (_inProgress) return _initializationCompleter.future;
    _inProgress = true;
    Future<void>.delayed(
      const Duration(milliseconds: 50),
      () => _handler(_inController.stream, _outSink),
    ).whenComplete(() {
      _initializationCompleter.complete();
      _inProgress = false;
    });
    return _initializationCompleter.future;
  }

  @override
  void add(In data) => _inController.add(data);

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _inController.addError(error, stackTrace);

  @override
  void close() => _inController.close();
}
