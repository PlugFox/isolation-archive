import 'dart:async';

import 'package:isolation/src/isolate/isolate_master.dart';

/// Entry point signature
typedef EntryPoint<Send, Receive, Argument> = void Function(
  Connection<Send, Receive> connection,
  Argument argument,
);

/// Connection
abstract class Connection<Send extends Object?, Receive extends Object?>
    implements EventSink<Send> {
  /// Lazily initialized isolate
  static Connection<S, R>
      create<S extends Object?, R extends Object?, A extends Object?>(
    EntryPoint<R, S, A> entryPoint,
    A argument,
  ) =>
          IsolateMaster<S, R, A>(entryPoint, argument);

  /// Initialize isolate
  static Future<Connection<Send, Receive>> spawn<Send extends Object?,
          Receive extends Object?, Argument extends Object?>(
    EntryPoint<Receive, Send, Argument> entryPoint,
    Argument argument,
  ) =>
      IsolateMaster.spawn<Send, Receive, Argument>(entryPoint, argument);

  /// Stream of data
  abstract final Stream<Receive> stream;

  // TODO: pause, resume, terminate, ping (healthcheck), close, stream, errorsAreFatal, dev metrics
  // Matiunin Mikhail <plugfox@gmail.com>, 15 May 2022

  // TODO: group multiple isolates inside one addition isolate
  // Matiunin Mikhail <plugfox@gmail.com>, 15 May 2022
}
