import 'package:freezed_annotation/freezed_annotation.dart';

part 'server_profile.freezed.dart';

/// Ein NAS mit bis zu zwei Adressen. Secrets (SID, Geräte-Token, optional
/// Passwort) liegen nicht hier, sondern im Secure Storage.
@freezed
abstract class ServerProfile with _$ServerProfile {
  const factory ServerProfile({
    /// `null`, solange das Profil noch nicht gespeichert ist.
    int? id,
    required String name,

    /// Primäre Adresse (LAN, DDNS oder Tailscale), wird zuerst probiert.
    /// Heißt aus historischen Gründen `lanUrl`.
    required String lanUrl,

    /// Optionale zweite Adresse als Fallback, wenn [lanUrl] nicht erreichbar
    /// ist.
    String? externalUrl,
    required String user,
  }) = _ServerProfile;
}
