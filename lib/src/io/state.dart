import 'package:meta/meta.dart';

/// {@template isolate_connection_state}
/// [IsolateConnectionState] represents the status of connection with
/// another isolate.
/// {@endtemplate}
@immutable
@internal
abstract class IsolateConnectionState {
  /// {@macro isolate_connection_state}
  const IsolateConnectionState();

  /// Initial unconnected status.
  ///
  /// {@macro isolate_connection_state}
  const factory IsolateConnectionState.initial() =
      InititalIsolateConnectionState._;

  /// Pattern matches the [IsolateConnectionState] instance.
  T map<T>({
    /// Initial unconnected status.
    required T Function(InititalIsolateConnectionState state) initial,

    /// Initialized status.
    required T Function(InitializationIsolateConnectionState state)
        initialization,

    /// The connection is established, connected.
    required T Function(EstablishedIsolateConnectionState state) established,

    /// The connection is closing.
    required T Function(ClosingIsolateConnectionState state) closing,

    /// The connection is closed.
    required T Function(ClosedIsolateConnectionState state) closed,
  });

  /// Pattern matches the [IsolateConnectionState] instance.
  T maybeMap<T>({
    /// If callbacks for state are not provided.
    required T Function() orElse,

    /// Initial unconnected status.
    T Function(InititalIsolateConnectionState state)? initial,

    /// Initialized status.
    T Function(InitializationIsolateConnectionState state)? initialization,

    /// The connection is established, connected.
    T Function(EstablishedIsolateConnectionState state)? established,

    /// The connection is closing.
    T Function(ClosingIsolateConnectionState state)? closing,

    /// The connection is closed.
    T Function(ClosedIsolateConnectionState state)? closed,
  }) =>
      map<T>(
        initial: initial ?? (_) => orElse(),
        initialization: initialization ?? (_) => orElse(),
        established: established ?? (_) => orElse(),
        closing: closing ?? (_) => orElse(),
        closed: closed ?? (_) => orElse(),
      );
}

/// Initial unconnected status.
class InititalIsolateConnectionState extends IsolateConnectionState {
  const InititalIsolateConnectionState._();

  @override
  T map<T>({
    required T Function(InititalIsolateConnectionState state) initial,
    required T Function(InitializationIsolateConnectionState state)
        initialization,
    required T Function(EstablishedIsolateConnectionState state) established,
    required T Function(ClosingIsolateConnectionState state) closing,
    required T Function(ClosedIsolateConnectionState state) closed,
  }) =>
      initial(this);

  /// Get state initialization in progress
  InitializationIsolateConnectionState inProgress() =>
      const InitializationIsolateConnectionState._();
}

/// Initialized status.
class InitializationIsolateConnectionState extends IsolateConnectionState {
  const InitializationIsolateConnectionState._();

  @override
  T map<T>({
    required T Function(InititalIsolateConnectionState state) initial,
    required T Function(InitializationIsolateConnectionState state)
        initialization,
    required T Function(EstablishedIsolateConnectionState state) established,
    required T Function(ClosingIsolateConnectionState state) closing,
    required T Function(ClosedIsolateConnectionState state) closed,
  }) =>
      initialization(this);

  /// Get state initialization in progress
  EstablishedIsolateConnectionState established() =>
      const EstablishedIsolateConnectionState._();

  /// The connection is closing.
  ClosingIsolateConnectionState closing() =>
      const ClosingIsolateConnectionState._();
}

/// The connection is established, connected.
class EstablishedIsolateConnectionState extends IsolateConnectionState {
  const EstablishedIsolateConnectionState._();

  @override
  T map<T>({
    required T Function(InititalIsolateConnectionState state) initial,
    required T Function(InitializationIsolateConnectionState state)
        initialization,
    required T Function(EstablishedIsolateConnectionState state) established,
    required T Function(ClosingIsolateConnectionState state) closing,
    required T Function(ClosedIsolateConnectionState state) closed,
  }) =>
      established(this);

  /// The connection is closing.
  ClosingIsolateConnectionState closing() =>
      const ClosingIsolateConnectionState._();
}

/// The connection is closing.
class ClosingIsolateConnectionState extends IsolateConnectionState {
  const ClosingIsolateConnectionState._();

  @override
  T map<T>({
    required T Function(InititalIsolateConnectionState state) initial,
    required T Function(InitializationIsolateConnectionState state)
        initialization,
    required T Function(EstablishedIsolateConnectionState state) established,
    required T Function(ClosingIsolateConnectionState state) closing,
    required T Function(ClosedIsolateConnectionState state) closed,
  }) =>
      closing(this);

  /// The connection is closed.
  ClosingIsolateConnectionState closed() =>
      const ClosingIsolateConnectionState._();
}

/// The connection is closed.
class ClosedIsolateConnectionState extends IsolateConnectionState {
  const ClosedIsolateConnectionState._();

  @override
  T map<T>({
    required T Function(InititalIsolateConnectionState state) initial,
    required T Function(InitializationIsolateConnectionState state)
        initialization,
    required T Function(EstablishedIsolateConnectionState state) established,
    required T Function(ClosingIsolateConnectionState state) closing,
    required T Function(ClosedIsolateConnectionState state) closed,
  }) =>
      closed(this);
}
