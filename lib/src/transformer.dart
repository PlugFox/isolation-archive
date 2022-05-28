import 'dart:async';

import 'package:isolation/src/handler.dart';
import 'package:isolation/src/logging.dart';
import 'package:isolation/src/transport.dart';
import 'package:meta/meta.dart';

/// {@template isolation_transformer}
/// IsolationTransformer stream transformer
/// {@endtemplate}
/// {@nodoc}
@immutable
class IsolationTransformer<In, Out> extends StreamTransformerBase<In, Out> {
  /// {@macro isolation_transformer}
  const IsolationTransformer({
    required IsolationHandler<In, Out> handler,
  }) : _handler = handler;

  final IsolationHandler<In, Out> _handler;

  @override
  Stream<Out> bind(Stream<In> stream) {
    config('IsolationTransformer bind on stream');
    final controller = stream.isBroadcast
        ? StreamController<Out>.broadcast(sync: true)
        : StreamController<Out>(
            sync: true,
          ); // ! WE MUST USE TRANSPORT CONTROLLER INSTEAD OF STREAM CONTROLLER !
    final transport = createTransport<In, Out>(_handler, controller.sink);
    void onListen() => _onListen(transport, stream, controller);
    return (controller..onListen = onListen).stream;
  }

  Future<void> _onListen(
    Transport<In, Out> transport,
    Stream<In> stream,
    StreamController<Out> controller,
  ) async {
    config('IsolationTransformer on listen subscribe');
    final sink = controller.sink;
    final subscription = stream.listen(null, cancelOnError: false);
    controller.onCancel = subscription.cancel;
    // TODO: we must use isolate instead of stream controller
    // Matiunin Mikhail <plugfox@gmail.com>, 29 May 2022
    final pause = subscription.pause;
    final resume = subscription.resume;
    await _initialize(transport, pause, resume);
    if (!stream.isBroadcast) {
      // TODO: Available to pause transport
      // Matiunin Mikhail <plugfox@gmail.com>, 28 May 2022
      controller
        ..onPause = pause
        ..onResume = resume;
    }
    final emitter = _emitter(transport);
    subscription
      ..onData(emitter)
      ..onError(sink.addError)
      ..onDone(() {
        // TODO: Send done message to isolate
        // Matiunin Mikhail <plugfox@gmail.com>, 29 May 2022
        config('IsolationTransformer subscription on done');
        sink.close();
        transport.close();
      });
  }

  Future<void> _initialize(
    Transport<In, Out> transport,
    void Function([Future<void>? resumeSignal]) pause,
    void Function() resume,
  ) async {
    if (transport.isInitialized) return;
    config('IsolationTransformer pause and await transport initialization');
    pause();
    await transport.initialize();
    resume();
    config('IsolationTransformer resume after transport initialization');
  }

  void Function(In data) _emitter(
    Transport<In, Out> transport,
  ) =>
      (In data) {
        assert(transport.isInitialized, 'Transport is not initialized');
        transport.add(data);
      };
} // end of IsolationTransformer
