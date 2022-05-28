import 'dart:async';

import 'package:isolation/src/connection_status.dart';
import 'package:isolation/src/develop.dart';
import 'package:meta/meta.dart';

/// [ConnectionStatus] owner
mixin ConnectionStatusOwner {
  /// Isolate communicator initialization status
  @protected
  @visibleForTesting
  ConnectionStatus get status => _status;
  ConnectionStatus _status = ConnectionStatus.initial;

  /// Change connection status
  @protected
  // ignore: use_setters_to_change_properties
  void setStatus(ConnectionStatus newStatus) {
    _status = newStatus;
    switch (newStatus) {
      case ConnectionStatus.established:
        _initilizationCompleter.complete();
        info('Establish connection');
        break;
      case ConnectionStatus.error:
        _initilizationCompleter.completeError(
          StateError('Error occurred while establishing connection'),
        );
        warning('Error occurred while establishing connection');
        break;
      case ConnectionStatus.initial:
        config('Initial state');
        break;
      case ConnectionStatus.initialization:
        info('Starts initialization');
        break;
      case ConnectionStatus.closing:
        info('Closing connection');
        break;
      case ConnectionStatus.closed:
        info('Closed connection');
        break;
    }
  }

  final Completer<void> _initilizationCompleter = Completer<void>();

  /// Initialize connection with another isolate
  @protected
  Future<void> initConnection();

  /// Await connection establishment and run callback
  @protected
  @mustCallSuper
  FutureOr<void> onInitConnection(
    FutureOr<void> Function() callback,
  ) {
    switch (status) {
      case ConnectionStatus.initial:
        return initConnection().then<void>((_) => callback());
      case ConnectionStatus.initialization:
        return _initilizationCompleter.future.then<void>((_) => callback());
      case ConnectionStatus.established:
        return callback();
      case ConnectionStatus.error:
        throw StateError(
          'Error occurred while establishing connection',
        );
      case ConnectionStatus.closing:
        throw StateError(
          'Unable to send data to isolate when connection is closing',
        );
      case ConnectionStatus.closed:
        throw StateError(
          'Unable to send data to isolate after connection has been closed',
        );
    }
  }
}
