import 'dart:async';
import 'dart:isolate';

import 'package:isolation/src/constant.dart';
import 'package:isolation/src/io/exception.dart';
import 'package:isolation/src/io/payload.dart';
import 'package:isolation/src/io/slave.dart';
import 'package:isolation/src/logging.dart';
import 'package:meta/meta.dart';

/// Entry point for the isolate.
@internal
void isolateEntryPoint(IsolatePayload payload) {
  SlaveIsolateConnection? conenction;
  runZonedGuarded<void>(
    () async {
      info('Execute entry payload in slave isolate');
      conenction = await payload();
    },
    (error, stackTrace) {
      severe(error, stackTrace, 'Root exception in slave isolate is catched');
      payload.exceptionPort.send(
        IsolateException(error, stackTrace),
      );
      if (payload.errorsAreFatal) {
        info('Closing slave isolate after fatal error');
        conenction?.close();
        Isolate.current.kill();
      }
    },
    zoneValues: <Object?, Object?>{
      kLogEnabled: payload.enableLogging,
    },
  );
}
