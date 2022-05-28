import 'dart:async';

import 'package:isolation/src/handler.dart';
import 'package:isolation/src/io/connection.dart';
import 'package:isolation/src/io/master.dart';
import 'package:isolation/src/io/state.dart';
import 'package:isolation/src/logging.dart';
import 'package:isolation/src/transport.dart';
import 'package:meta/meta.dart';

/// Create stub transport.
@internal
Transport<In, Out> createTransport<In, Out>(
  IsolationHandler<In, Out> handler,
  EventSink<Out> output,
) =>
    IsolateTransport<In, Out>(handler, output);

/// {@template isolate_transport}
/// Isolate transport.
/// {@endtemplate}
@internal
class IsolateTransport<In, Out> extends Transport<In, Out> {
  /// {@macro isolate_transport}
  IsolateTransport(IsolationHandler<In, Out> handler, EventSink<Out> out)
      : _connection = MasterIsolateConnection<In, Out>(
          handler: handler,
          eventsFromSlave: out,
        ) {
    fine('IsolateTransport created');
  }
  final Completer<void> _initializationCompleter = Completer<void>();
  final IsolateConnection<In, Out> _connection;

  IsolateConnectionState _state = const IsolateConnectionState.initial();

  @override
  bool get isInitialized => _initializationCompleter.isCompleted;

  @override
  FutureOr<void> initialize() => _state.map<FutureOr<void>>(
        initial: (state) {
          {
            config('IsolateTransport initialization started');
            _state = state.inProgress();
            _estabilishConnection()
                .catchError((Object error, StackTrace stackTrace) {
              _initializationCompleter.completeError(error, stackTrace);
              close();
            });
            return _initializationCompleter.future;
          }
        },
        initialization: (_) {
          assert(
            false,
            'Isolate transport initialization already in progress.',
          );
          return _initializationCompleter.future;
        },
        established: (_) {
          assert(
            false,
            'Isolate transport already initialized.',
          );
        },
        closing: (_) {
          assert(
            false,
            'Isolate transport now closing connection.',
          );
        },
        closed: (_) {
          assert(
            false,
            'Isolate transport already closed.',
          );
        },
      );

  Future<void> _estabilishConnection() async {
    await _connection.connect();
    _state.maybeMap<void>(
      orElse: () {
        assert(
          false,
          'Can not finish initialization, '
          'because initialization is not in progress.',
        );
      },
      initialization: (state) {
        _state = state.established();
        _initializationCompleter.complete();
        config('IsolateTransport initialization successfully finished');
      },
    );
  }

  @override
  void add(In data) => _state.maybeMap<void>(
        orElse: () {
          assert(
            false,
            'Can not send data to isolate, '
            'because connection between isolates are not established',
          );
        },
        established: (_) => _connection.add(data),
      );

  @override
  void addError(Object error, [StackTrace? stackTrace]) =>
      _state.maybeMap<void>(
        orElse: () {
          assert(
            false,
            'Can not send error to isolate, '
            'because connection between isolates are not established',
          );
        },
        established: (_) => _connection.addError(error, stackTrace),
      );

  @override
  void close() => _state.maybeMap<void>(
        orElse: () {
          assert(
            false,
            'Can not close connection with isolate, '
            'because connection with isolate are not established',
          );
        },
        initialization: (state) {
          warning(
            'IsolateTransport connection closing started after initialization',
          );
          _state = state.closing();
          _forceClose();
        },
        established: (state) {
          config('IsolateTransport connection closing started');
          _state = state.closing();
          _forceClose();
        },
      );

  Future<void> _forceClose() async {
    _connection.close();
    _state.maybeMap<void>(
      orElse: () {
        assert(
          false,
          'Can not close connection with isolate, '
          'because it is not closing now.',
        );
      },
      closing: (state) => _state = state.closed(),
    );
    info(
      'IsolateTransport successfully connection closed',
    );
  }
}
