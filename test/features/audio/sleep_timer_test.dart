import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nuvo_explorer/features/audio/domain/sleep_timer.dart';

void main() {
  test('feste Dauer: pausiert genau nach Ablauf', () {
    fakeAsync((async) {
      var expired = 0;
      final timer = SleepTimer(() => expired++)
        ..start(const Duration(minutes: 15));
      async.elapse(const Duration(minutes: 14, seconds: 59));
      expect(expired, 0);
      expect(timer.active, isTrue);
      async.elapse(const Duration(seconds: 1));
      expect(expired, 1);
      expect(timer.active, isFalse);
    });
  });

  test('neuer Start ersetzt den alten, cancel stoppt', () {
    fakeAsync((async) {
      var expired = 0;
      final timer = SleepTimer(() => expired++)
        ..start(const Duration(minutes: 15))
        ..start(const Duration(minutes: 30));
      async.elapse(const Duration(minutes: 20));
      expect(expired, 0);
      timer.cancel();
      async.elapse(const Duration(hours: 1));
      expect(expired, 0);
    });
  });

  test('Ende des Titels: erst beim Titelende', () {
    var expired = 0;
    final timer = SleepTimer(() => expired++);
    expect(timer.trackEnded(), isFalse);
    timer.startEndOfTrack();
    expect(timer.endOfTrack, isTrue);
    expect(timer.trackEnded(), isTrue);
    expect(expired, 1);
    expect(timer.active, isFalse);
    expect(timer.trackEnded(), isFalse);
  });
}
