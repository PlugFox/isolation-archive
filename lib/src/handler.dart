import 'dart:async';

/// An event handler is responsible for reacting to an incoming [In]
/// and can emit zero or more [Out] via the [sink].
typedef IsolationHandler<In, Out> = FutureOr<void> Function(
  Stream<In> stream,
  EventSink<Out> sink,
);
