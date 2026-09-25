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
    required String lanUrl,
    String? externalUrl,
    required String user,
  }) = _ServerProfile;
}
