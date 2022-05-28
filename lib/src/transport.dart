import 'dart:async';

export 'package:isolation/src/st/transport.dart'
    // ignore: uri_does_not_exist
    if (dart.library.js) 'package:isolation/src/st/transport.dart'
    // ignore: uri_does_not_exist
    if (dart.library.io) 'package:isolation/src/io/transport.dart';

/// Transport between two isolates/workers.
/// {@nodoc}
abstract class Transport<In, Out> implements EventSink<In> {
  /// Transport already initialized.
  abstract final bool isInitialized;

  /// Initialize the transport if it is not already initialized.
  FutureOr<void> initialize();
}
