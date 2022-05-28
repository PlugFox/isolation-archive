import 'dart:async';
import 'dart:isolate';

import 'package:isolation/src/delegating_event_sink.dart';
import 'package:isolation/src/io/channel.dart';
import 'package:isolation/src/io/connection.dart';
import 'package:isolation/src/io/exception.dart';
import 'package:isolation/src/io/service_messages.dart';
import 'package:isolation/src/logging.dart';
import 'package:meta/meta.dart';

/// {@template slave_isolate_connection}
/// Isolate helper, that helps to create and manage another isolate.
/// {@endtemplate}
@internal
class SlaveIsolateConnection<In, Out> extends IsolateConnection<In, Out> {
  /// {@macro slave_isolate_connection}
  SlaveIsolateConnection({
    required SendPort dataSendPort,
    required SendPort exceptiondataSendPort,
    required SendPort servicedataSendPort,
  }) : super(
          dataChannel: IsolateChannel<In, Out>(
            dataSendPort,
          ),
          exceptionChannel: IsolateChannel<IsolateException, IsolateException>(
            exceptiondataSendPort,
          ),
          serviceChannel: IsolateChannel<Object?, Object?>(
            servicedataSendPort,
          ),
        ) {
    fine('SlaveIsolateConnection created');
  }

  /// Combine data and exception from master isolate
  final StreamController<Out> _eventsFromMaster = StreamController<Out>();

  /// Sink for data and exception
  EventSink<In> get sink => DelegatingEventSink<In>(this);

  /// Data and exception from master isolate
  Stream<Out> get stream => _eventsFromMaster.stream;

  StreamSubscription<Out>? _dataSubscription;
  StreamSubscription<IsolateException>? _exceptionSubscription;

  @override
  Future<void> connect() async {
    fine('SlaveIsolateConnection connection is started');
    await super.connect();
    addServiceMessage(
      IsolateSendPorts(
        dataPort: super.dataChannel.receivePort.sendPort,
        exceptionPort: super.exceptionChannel.receivePort.sendPort,
        servicePort: super.serviceChannel.receivePort.sendPort,
      ),
    );
    _registrateListeners();
  }

  void _registrateListeners() {
    fine('SlaveIsolateConnection start listening on data channel');
    _dataSubscription = dataChannel.receivePort.cast<Out>().listen(
      _eventsFromMaster.add,
      onError: (Object error, StackTrace stackTrace) {
        warning(
          error,
          stackTrace,
          'SlaveIsolateConnection exception on data channel listener',
        );
        _eventsFromMaster.addError(error, stackTrace);
      },
      cancelOnError: false,
    );

    fine('SlaveIsolateConnection start listening on exception channel');
    _exceptionSubscription =
        exceptionChannel.receivePort.cast<IsolateException>().listen(
      (msg) => _eventsFromMaster.addError(msg.exception, msg.stackTrace),
      onError: (Object error, StackTrace stackTrace) {
        warning(
          error,
          stackTrace,
          'SlaveIsolateConnection exception on exception channel listener',
        );
        _eventsFromMaster.addError(error, stackTrace);
      },
      cancelOnError: false,
    );
  }

  @override
  void close() {
    try {
      addServiceMessage(null);
      super.close();
      _eventsFromMaster.close();
      _dataSubscription?.cancel();
      _exceptionSubscription?.cancel();
    } finally {
      Isolate.current.kill();
    }
  }
}
