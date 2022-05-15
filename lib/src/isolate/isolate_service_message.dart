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
  });

  /// Map specific service message
  T maybeMap<T extends Object?>({
    required T Function() orElse,
    T Function(SendPortMessage message)? sendPort,
    T Function(HandshakeCompletedMessage message)? handshakeCompleted,
    T Function(PingMessage message)? ping,
    T Function(PongMessage message)? pong,
  }) =>
      map<T>(
        sendPort: sendPort ?? (_) => orElse(),
        handshakeCompleted: handshakeCompleted ?? (_) => orElse(),
        ping: ping ?? (_) => orElse(),
        pong: pong ?? (_) => orElse(),
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
  }) =>
      sendPort(this);
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
  }) =>
      handshakeCompleted(this);
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
  }) =>
      ping(this);
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
  }) =>
      pong(this);
}
