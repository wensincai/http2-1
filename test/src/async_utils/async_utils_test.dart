// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:unittest/unittest.dart';
import 'package:http2/src/async_utils/async_utils.dart';

main() {
  group('async_utils', () {
    test('buffer-indicator', () {
      var bi = new BufferIndicator();
      bi.bufferEmptyEvents.listen(expectAsync((_) {}, count: 2));

      expect(bi.wouldBuffer, true);

      bi.markUnBuffered();
      expect(bi.wouldBuffer, false);

      bi.markBuffered();
      expect(bi.wouldBuffer, true);
      bi.markBuffered();
      expect(bi.wouldBuffer, true);

      bi.markUnBuffered();
      expect(bi.wouldBuffer, false);
      bi.markUnBuffered();
      expect(bi.wouldBuffer, false);

      bi.markBuffered();
      expect(bi.wouldBuffer, true);
      bi.markBuffered();
      expect(bi.wouldBuffer, true);
    });

    test('buffered-sink', () {
      var c = new StreamController();
      var bs = new BufferedSink(c);

      expect(bs.bufferIndicator.wouldBuffer, true);
      var sub = c.stream.listen(expectAsync((_) {}, count: 2));

      expect(bs.bufferIndicator.wouldBuffer, false);

      sub.pause();
      Timer.run(expectAsync(() {
        expect(bs.bufferIndicator.wouldBuffer, true);
        bs.sink.add([1]);

        sub.resume();
        Timer.run(expectAsync(() {
          expect(bs.bufferIndicator.wouldBuffer, false);
          bs.sink.add([2]);

          Timer.run(expectAsync(() {
            sub.cancel();
            expect(bs.bufferIndicator.wouldBuffer, false);
          }));
        }));
      }));
    });

    test('buffered-bytes-writer', () async {
      var c = new StreamController();
      var writer = new BufferedBytesWriter(c);

      expect(writer.bufferIndicator.wouldBuffer, true);

      var bytesFuture = c.stream.fold([], (b, d) => b..addAll(d));

      expect(writer.bufferIndicator.wouldBuffer, false);

      writer.add([1, 2]);
      writer.add([3, 4]);

      writer.addBufferedData([5, 6]);
      expect(() => writer.add([7, 8]), throwsStateError);

      writer.addBufferedData([7, 8]);
      await writer.close();
      expect(await bytesFuture, [1, 2, 3, 4, 5, 6, 7, 8]);
    });
  });
}
