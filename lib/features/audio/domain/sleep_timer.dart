import 'dart:async';

/// Sleep-Timer: pausiert nach einer festen Zeit oder am Ende des Titels.
class SleepTimer {
  SleepTimer(this._onExpire);

  static const presets = [15, 30, 45, 60];

  final void Function() _onExpire;
  Timer? _timer;
  DateTime? _endsAt;
  bool _endOfTrack = false;

  bool get active => _timer != null || _endOfTrack;
  bool get endOfTrack => _endOfTrack;

  /// Restzeit bei fester Dauer, sonst `null`.
  Duration? remaining([DateTime? now]) =>
      _endsAt?.difference(now ?? DateTime.now());

  void start(Duration duration) {
    cancel();
    _endsAt = DateTime.now().add(duration);
    _timer = Timer(duration, _expire);
  }

  void startEndOfTrack() {
    cancel();
    _endOfTrack = true;
  }

  /// Vom Player, wenn ein Titel zu Ende gelaufen ist. Liefert `true`, wenn
  /// der Timer dabei abgelaufen ist (dann nicht weiterspielen).
  bool trackEnded() {
    if (!_endOfTrack) return false;
    _expire();
    return true;
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _endsAt = null;
    _endOfTrack = false;
  }

  void _expire() {
    cancel();
    _onExpire();
  }
}
