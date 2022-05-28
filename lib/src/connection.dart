import 'dart:async';

import 'package:isolation/src/isolate/isolate_master.dart';
import 'package:meta/meta.dart';

/// Entry point signature
typedef EntryPoint<Send, Receive, Argument> = void Function(
  Connection<Send, Receive> connection,
  Argument argument,
);

/// Connection
abstract class Connection<Send extends Object?, Receive extends Object?>
    implements EventSink<Send> {
  /// Lazily initialized isolate
  @factory
  static Connection<S, R>
      create<S extends Object?, R extends Object?, A extends Object?>(
    EntryPoint<R, S, A> entryPoint,
    A argument, {
    bool errorsAreFatal = true,
  }) =>
          IsolateMaster<S, R, A>(
            entryPoint,
            argument,
            errorsAreFatal: errorsAreFatal,
          );

  /// Initialize isolate
  static Future<Connection<Send, Receive>> spawn<Send extends Object?,
          Receive extends Object?, Argument extends Object?>(
    EntryPoint<Receive, Send, Argument> entryPoint,
    Argument argument, {
    bool errorsAreFatal = true,
  }) =>
      IsolateMaster.spawn<Send, Receive, Argument>(
        entryPoint,
        argument,
        errorsAreFatal: errorsAreFatal,
      );

  /// Stream of data
  abstract final Stream<Receive> stream;

  /// Sets whether uncaught errors will terminate the isolate.
  ///
  /// If errors are fatal, any uncaught error will terminate the isolate
  /// event loop and shut down the isolate.
  abstract final bool errorsAreFatal;

  @override
  void close();

  // TODO: pause, resume, terminate, ping (healthcheck), errorsAreFatal, dev metrics
  // Matiunin Mikhail <plugfox@gmail.com>, 15 May 2022

  // TODO: group multiple isolates inside one addition isolate
  // Matiunin Mikhail <plugfox@gmail.com>, 15 May 2022
}
