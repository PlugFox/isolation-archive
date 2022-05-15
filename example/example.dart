import 'dart:async';

@pragma('vm:entry-point')
void main([List<String>? args]) => runZonedGuarded<Future<void>>(() async {
      // ...
    }, (error, stackTrace) {
      print(error);
    });
