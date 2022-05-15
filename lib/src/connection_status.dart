/// [ConnectionStatus] represents the status of connection with
/// another isolate or worker.
enum ConnectionStatus {
  /// Initial unconnected status.
  initial,

  /// Initialized status.
  initialization,

  /// The connection is established, connected.
  established,

  /// Error occurred while establishing connection.
  error,

  /// The connection is closing.
  closing,

  /// The connection is closed.
  closed,
}
