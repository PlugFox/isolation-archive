import 'package:isolation/src/handler.dart';
import 'package:isolation/src/transformer.dart';

export 'package:isolation/src/transformer.dart' show IsolationTransformer;

/// IsolationTransformer extension methods.
/// sourceStream.isolationTransformer<T>()
/// {@nodoc}
extension IsolationTransformerX<In> on Stream<In> {
  /// {@macro isolation_transformer}
  Stream<Out> isolate<Out>(
    /// Handler for the stream data channel.
    IsolationHandler<In, Out> handler,
  ) =>
      transform<Out>(
        IsolationTransformer<In, Out>(handler: handler),
      );
} // end of IsolationTransformerX extension
