import 'package:isolation/src/connection.dart';
import 'package:isolation/src/connection_exception.dart';
import 'package:isolation/src/connection_owner.dart';
import 'package:isolation/src/isolate/isolate_channel.dart';
import 'package:isolation/src/isolate/isolate_service_message.dart';
import 'package:meta/meta.dart';

/// {@template isolate_base.isolate_base}
/// Base class for master and slave isolates
/// {@endtemplate}
abstract class IsolateBase<Send extends Object?, Receive extends Object?>
    with ConnectionStatusOwner
    implements Connection<Send, Receive> {
  /// {@macro isolate_base.isolate_base}
  IsolateBase({
    required this.dataChannel,
    required this.exceptionChannel,
    required this.serviceChannel,
  }) : messages = serviceChannel.receivePort
            .cast<IsolateServiceMessage>()
            .asBroadcastStream();

  /// Channel for data
  @protected
  final IsolateChannel<Send, Receive> dataChannel;

  /// Channel for exceptions
  @protected
  final IsolateChannel<ConnectionException, ConnectionException>
      exceptionChannel;

  /// Channel for service messages
  @protected
  final IsolateChannel<IsolateServiceMessage, IsolateServiceMessage>
      serviceChannel;

  /// Stream of service messages
  final Stream<IsolateServiceMessage> messages;
}
