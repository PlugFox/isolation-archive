@Timeout(Duration(seconds: 5))
@Tags(<String>['io'])
import 'package:test/test.dart';

import 'stream/stream_test.dart';

void main([List<String>? args]) {
  streamTest();
}
