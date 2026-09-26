#!/usr/bin/env bash
# Gerätetest-Helfer für den E2E-Lauf (docs/E2E-RUN.md). Ruft ausschließlich
# das Windows-adb (`adb.exe`, siehe CLAUDE.md) mit explizitem Gerät auf.
#
#   DEVICE=<id> [RUN=<name>] tool/e2e/device.sh <befehl> [argumente]
#
# Befehle: install, start, stop, clear, tap-label <text>, scroll-to <text>,
#   tap-row-action <zeile> <knopf>, tap-xy <x> <y>,
#   type <text>, type-env <VARIABLE>, clear-field, hide-keyboard, back, home, enter, swipe <x1> <y1> <x2> <y2>,
#   shot <name>, dump, labels, wait-label <text> [sekunden], has-label <text>,
#   logcat-start, logcat-stop, unlock (PIN aus $E2E_PIN), rotate <0|1>
#
# Artefakte (Screenshots, Dumps, Logcat) landen unter .e2e/<RUN>/ – sie
# enthalten echte Dateinamen und werden nie committet (.gitignore).
# Zugangsdaten stehen nie in diesem Skript: `type-env NAS_PASS` liest den Wert
# aus der Umgebung und gibt ihn nicht aus.
set -euo pipefail

: "${DEVICE:?DEVICE=<adb-id> setzen}"
RUN="${RUN:-$(date +%Y%m%d)}"
OUT=".e2e/$RUN"
PKG=de.jw29435.synology_explorer
APK=build/app/outputs/flutter-apk/app-debug.apk
mkdir -p "$OUT"

adb() { timeout "${ADB_TIMEOUT:-30}" adb.exe -s "$DEVICE" "$@"; }

# UI-Baum als XML auf stdout. Scheitert, solange die App ständig Frames
# erzeugt (z. B. Wiedergabe-Fortschritt: „could not get idle state“) – dann
# bleibt nur Screenshot + tap-xy. Die alte Datei wird vorher gelöscht, damit
# nie ein veralteter Baum gelesen wird.
dump_xml() {
  adb shell rm -f /sdcard/e2e_dump.xml
  adb shell uiautomator dump /sdcard/e2e_dump.xml >/dev/null 2>&1 || true
  if ! adb exec-out cat /sdcard/e2e_dump.xml 2>/dev/null | grep -q '<hierarchy'; then
    echo "uiautomator dump gescheitert (keine Ruhe im UI?)" >&2
    return 1
  fi
  adb exec-out cat /sdcard/e2e_dump.xml
}

# Mittelpunkt des besten Knotens zu einem Text/Label: exakter Treffer vor
# Treffer einer Zeile vor Teiltreffer; bei Gleichstand der kleinste Knoten.
find_center() {
  dump_xml | python3 -c '
import re, sys, xml.etree.ElementTree as ET
want = sys.argv[1]
max_rank = int(sys.argv[2])
try:
    root = ET.fromstring(sys.stdin.read())
except ET.ParseError:
    sys.exit(1)
best = None
for n in root.iter("node"):
    for attr in ("text", "content-desc"):
        v = (n.get(attr) or "").strip()
        if not v:
            continue
        if v == want: rank = 0
        elif want in v.splitlines(): rank = 1
        elif want in v: rank = 2
        else: continue
        if rank > max_rank: continue
        m = re.findall(r"\d+", n.get("bounds", ""))
        if len(m) != 4: continue
        x1, y1, x2, y2 = map(int, m)
        key = (rank, (x2 - x1) * (y2 - y1))
        if best is None or key < best[0]:
            best = (key, ((x1 + x2) // 2, (y1 + y2) // 2))
if best is None:
    sys.exit(1)
print(*best[1])
' "$1" "${2:-2}"
}

# Text für `input text`: Leerzeichen als %s, für die Geräte-Shell gequotet.
# Zeichenweise – in einem Rutsch verliert die Tastatur Zeichen.
input_text() {
  local i c esc
  for ((i = 0; i < ${#1}; i++)); do
    c="${1:i:1}"
    esc=$(printf '%s' "$c" | sed "s/'/'\\\\''/g; s/ /%s/g")
    adb shell "input text '$esc'"
  done
}

cmd="${1:?Befehl fehlt}"
shift || true
case "$cmd" in
  install) ADB_TIMEOUT=300 adb install -r "$(wslpath -w "$APK")" ;;
  start) adb shell am start -n "$PKG/.MainActivity" >/dev/null ;;
  stop) adb shell am force-stop "$PKG" ;;
  clear) adb shell pm clear "$PKG" ;;
  tap-xy) adb shell input tap "$1" "$2" ;;
  tap-label)
    if ! xy=$(find_center "$1"); then
      echo "nicht gefunden: $1" >&2
      exit 1
    fi
    # shellcheck disable=SC2086
    adb shell input tap $xy
    ;;
  scroll-to)
    # Nach oben wischen, bis [text] sichtbar ist (höchstens 8-mal).
    for _ in 1 2 3 4 5 6 7 8; do
      find_center "$1" 1 >/dev/null && exit 0
      adb shell input swipe 540 1700 540 900 400
      sleep 1
    done
    echo "nicht gefunden: $1" >&2
    exit 1
    ;;
  tap-row-action)
    # Knopf [2] (z. B. „Mehr“) in der Zeile, deren erste Zeile [1] ist.
    xy=$(dump_xml | python3 -c '
import re, sys, xml.etree.ElementTree as ET
row, action = sys.argv[1], sys.argv[2]
nodes = []
for n in ET.fromstring(sys.stdin.read()).iter("node"):
    m = re.findall(r"\d+", n.get("bounds", ""))
    if len(m) == 4:
        nodes.append(((n.get("content-desc") or n.get("text") or "").strip(), list(map(int, m))))
rows = [b for v, b in nodes if v.split("\n")[0] == row]
if not rows: sys.exit(1)
r = rows[0]
for v, b in nodes:
    if v == action and b[1] >= r[1] - 5 and b[3] <= r[3] + 5:
        print((b[0] + b[2]) // 2, (b[1] + b[3]) // 2); sys.exit(0)
sys.exit(1)
' "$1" "$2") || { echo "nicht gefunden: $1 / $2" >&2; exit 1; }
    # shellcheck disable=SC2086
    adb shell input tap $xy
    ;;
  has-label) find_center "$1" >/dev/null ;;
  wait-label)
    deadline=$((SECONDS + ${2:-15}))
    until find_center "$1" >/dev/null; do
      if ((SECONDS >= deadline)); then
        echo "Zeitüberschreitung: $1" >&2
        exit 1
      fi
      sleep 1
    done
    ;;
  type) input_text "$1" ;;
  type-env)
    value="${!1:?Variable $1 nicht gesetzt}"
    input_text "$value"
    ;;
  hide-keyboard)
    # Nur wenn die Tastatur offen ist – sonst wäre KEYCODE_BACK ein Zurück.
    if adb shell dumpsys input_method | grep -q 'mInputShown=true'; then
      adb shell input keyevent KEYCODE_BACK
      sleep 1
    fi
    ;;
  clear-field)
    adb shell input keyevent KEYCODE_MOVE_END
    adb shell input keyevent $(printf 'KEYCODE_DEL %.0s' $(seq 1 60))
    ;;
  back) adb shell input keyevent KEYCODE_BACK ;;
  home) adb shell input keyevent KEYCODE_HOME ;;
  enter) adb shell input keyevent KEYCODE_ENTER ;;
  swipe) adb shell input swipe "$1" "$2" "$3" "$4" "${5:-300}" ;;
  shot)
    name=$(printf '%s' "$1" | tr -c 'A-Za-z0-9_.-' '_')
    adb exec-out screencap -p >"$OUT/$name.png"
    echo "$OUT/$name.png"
    ;;
  dump) dump_xml ;;
  labels)
    dump_xml | python3 -c '
import sys, xml.etree.ElementTree as ET
for n in ET.fromstring(sys.stdin.read()).iter("node"):
    for a in ("text", "content-desc"):
        v = (n.get(a) or "").strip()
        if v: print(n.get("bounds"), repr(v))
'
    ;;
  logcat-start)
    adb logcat -c
    # Nur Flutter-Ausgaben und Abstürze/ANR – keine Formulardaten anderer Tags.
    nohup timeout 7200 adb.exe -s "$DEVICE" logcat -v time \
      flutter:V AndroidRuntime:E ActivityManager:W '*:S' \
      >>"$OUT/logcat.txt" 2>&1 &
    echo $! >"$OUT/logcat.pid"
    ;;
  logcat-stop)
    if [[ -f "$OUT/logcat.pid" ]]; then
      kill "$(cat "$OUT/logcat.pid")" 2>/dev/null || true
      rm -f "$OUT/logcat.pid"
    fi
    ;;
  unlock)
    : "${E2E_PIN:?E2E_PIN nicht gesetzt}"
    adb shell input keyevent KEYCODE_WAKEUP
    if adb shell dumpsys window | grep -q 'mDreamingLockscreen=true\|isKeyguardShowing=true\|mShowingLockscreen=true'; then
      adb shell input swipe 540 1800 540 600 300
      sleep 1
      input_text "$E2E_PIN"
      adb shell input keyevent KEYCODE_ENTER
    fi
    ;;
  rotate)
    adb shell settings put system accelerometer_rotation 0
    adb shell settings put system user_rotation "$1"
    ;;
  *)
    echo "Unbekannter Befehl: $cmd" >&2
    exit 2
    ;;
esac
