@Timeout(Duration(seconds: 5))
@TestOn('browser')
@Tags(<String>['js'])

import 'package:test/test.dart';

import 'stream/stream_test.dart';

void main() {
  streamTest();
}
