import 'dart:async';

/// {@template isolation}
/// Isolate helper class.
/// {@endtemplate}
class Isolation<T extends Object?> implements EventSink<T> {
  @override
  void add(T event) {
    // TODO: implement add
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    // TODO: implement addError
  }

  @override
  void close() {
    // TODO: implement close
  }
}
