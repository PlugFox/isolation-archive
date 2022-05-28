import 'dart:isolate';

import 'package:meta/meta.dart';

/// {@template isolate_send_ports}
/// Send ports passed between isolates.
/// {@endtemplate}
/// {@nodoc}
@immutable
class IsolateSendPorts {
  /// {@macro service_messages}
  const IsolateSendPorts({
    required this.dataPort,
    required this.exceptionPort,
    required this.servicePort,
  });

  /// Data port
  final SendPort dataPort;

  /// Exception port
  final SendPort exceptionPort;

  /// Service port
  final SendPort servicePort;
}
