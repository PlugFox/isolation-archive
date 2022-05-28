@internal
import 'dart:isolate';

import 'package:meta/meta.dart';

/// {@template isolate_service_message}
/// Service message
/// {@endtemplate}
@immutable
abstract class IsolateServiceMessage {
  /// {@macro isolate_service_message}
  const IsolateServiceMessage();

  /// Map specific service message
  T map<T extends Object?>({
    required T Function(SendPortMessage message) sendPort,
    required T Function(HandshakeCompletedMessage message) handshakeCompleted,
    required T Function(PingMessage message) ping,
    required T Function(PongMessage message) pong,
    required T Function(CloseMessage message) close,
  });

  /// Map specific service message
  T maybeMap<T extends Object?>({
    required T Function() orElse,
    T Function(SendPortMessage message)? sendPort,
    T Function(HandshakeCompletedMessage message)? handshakeCompleted,
    T Function(PingMessage message)? ping,
    T Function(PongMessage message)? pong,
    T Function(CloseMessage message)? close,
  }) =>
      map<T>(
        sendPort: sendPort ?? (_) => orElse(),
        handshakeCompleted: handshakeCompleted ?? (_) => orElse(),
        ping: ping ?? (_) => orElse(),
        pong: pong ?? (_) => orElse(),
        close: close ?? (_) => orElse(),
      );
}

/// {@template isolate_service_message.send_port}
/// Pass [SendPort] between isolates
/// {@endtemplate}
class SendPortMessage extends IsolateServiceMessage {
  /// {@macro isolate_service_message.send_port}
  const SendPortMessage({
    required this.dataPort,
    required this.exceptionPort,
    required this.servicePort,
  });

  /// Isolate payload data port
  final SendPort dataPort;

  /// Isolate payload exception port
  final SendPort exceptionPort;

  /// Isolate payload service port
  final SendPort servicePort;

  @override
  T map<T extends Object?>({
    required T Function(SendPortMessage message) sendPort,
    required T Function(HandshakeCompletedMessage message) handshakeCompleted,
    required T Function(PingMessage message) ping,
    required T Function(PongMessage message) pong,
    required T Function(CloseMessage message) close,
  }) =>
      sendPort(this);

  @override
  String toString() => 'SendPortMessage';
}

/// {@template isolate_service_message.handshake_completed}
/// Handshake successfuly completed message
/// {@endtemplate}
class HandshakeCompletedMessage extends IsolateServiceMessage {
  /// {@macro isolate_service_message.handshake_completed}
  const HandshakeCompletedMessage({
    required this.dataPort,
    required this.exceptionPort,
    required this.servicePort,
  });

  /// Isolate payload data port
  final SendPort dataPort;

  /// Isolate payload exception port
  final SendPort exceptionPort;

  /// Isolate payload service port
  final SendPort servicePort;

  @override
  T map<T extends Object?>({
    required T Function(SendPortMessage message) sendPort,
    required T Function(HandshakeCompletedMessage message) handshakeCompleted,
    required T Function(PingMessage message) ping,
    required T Function(PongMessage message) pong,
    required T Function(CloseMessage message) close,
  }) =>
      handshakeCompleted(this);

  @override
  String toString() => 'HandshakeCompletedMessage';
}

/// {@template isolate_service_message.ping}
/// Ping message
/// {@endtemplate}
class PingMessage extends IsolateServiceMessage {
  /// {@macro isolate_service_message.ping}
  const PingMessage(this.payload);

  /// Payload
  final Capability payload;

  @override
  T map<T extends Object?>({
    required T Function(SendPortMessage message) sendPort,
    required T Function(HandshakeCompletedMessage message) handshakeCompleted,
    required T Function(PingMessage message) ping,
    required T Function(PongMessage message) pong,
    required T Function(CloseMessage message) close,
  }) =>
      ping(this);

  @override
  String toString() => 'PingMessage';
}

/// {@template isolate_service_message.pong}
/// Pong message
/// {@endtemplate}
class PongMessage extends IsolateServiceMessage {
  /// {@macro isolate_service_message.pong}
  const PongMessage(this.payload);

  /// Payload
  final Capability payload;

  @override
  T map<T extends Object?>({
    required T Function(SendPortMessage message) sendPort,
    required T Function(HandshakeCompletedMessage message) handshakeCompleted,
    required T Function(PingMessage message) ping,
    required T Function(PongMessage message) pong,
    required T Function(CloseMessage message) close,
  }) =>
      pong(this);

  @override
  String toString() => 'PongMessage';
}

/// {@template isolate_service_message.close}
/// Close message
/// {@endtemplate}
class CloseMessage extends IsolateServiceMessage {
  /// {@macro isolate_service_message.close}
  const CloseMessage();

  @override
  T map<T extends Object?>({
    required T Function(SendPortMessage message) sendPort,
    required T Function(HandshakeCompletedMessage message) handshakeCompleted,
    required T Function(PingMessage message) ping,
    required T Function(PongMessage message) pong,
    required T Function(CloseMessage message) close,
  }) =>
      close(this);

  @override
  String toString() => 'CloseMessage';
}
