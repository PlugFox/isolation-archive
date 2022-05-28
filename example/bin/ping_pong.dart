import 'dart:async';

import 'package:isolation/isolation.dart';

@pragma('vm:entry-point')
void main([List<String>? args]) => runZonedGuarded<Future<void>>(
      () async {
        final connection = await Connection.spawn<int, String, void>(
          _entryPoint,
          null,
          errorsAreFatal: true,
        );
        await connection.stream
            .take(2)
            .forEach(print)
            .timeout(const Duration(seconds: 2));
        connection
          ..add(1)
          ..add(2)
          ..close();
        //exit(0);
      },
      (error, stackTrace) {
        print(error);
        //exit(2);
      },
    );

// TODO: error with type swap left and right
// Matiunin Mikhail <plugfox@gmail.com>, 28 May 2022
void _entryPoint(Connection connection, void argument) {
  connection.stream.map((event) => event.toString()).forEach(connection.add);
}
