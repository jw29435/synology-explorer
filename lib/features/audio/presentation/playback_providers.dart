import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ob gerade etwas abgespielt wird; dann reserviert die Shell den Platz für
/// den Mini-Player. Der Player selbst kommt in M2.
final hasActivePlaybackProvider = Provider<bool>((ref) => false);
