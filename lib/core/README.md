# core

Geteilte Infrastruktur, die mehrere Features nutzen. Unterordner entstehen mit dem ersten Code:

- `network/` – `SynoApiClient` (dio, LAN/extern, SID-Interceptor, Zertifikat-Pinning, Fehler-Mapping auf `SynoException`)
- `auth/` – `SessionManager`: Login, OTP, Geräte-Token, Re-Login-Policy, Logout
- `storage/` – drift-Datenbank, Secure Storage, Medien-Cache
- `l10n/` – Hilfen rund um Lokalisierung (die ARB-Dateien selbst liegen in `lib/l10n/`)
- `utils/` – kleine, featureübergreifende Helfer
- `errors/` – gemeinsame Fehlertypen
