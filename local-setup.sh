#!/usr/bin/env bash
# Lokales Setup für Flutter + Android-SDK unter WSL2 (Ubuntu 22.04). Einmal ausführen: bash local-setup.sh
# Danach neue Shell öffnen (oder: source ~/.bashrc) und `flutter doctor` prüfen.
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.35.4}"   # aktuelle stable prüfen: https://docs.flutter.dev/release/archive
CMDLINE_TOOLS="${CMDLINE_TOOLS:-11076708}"     # Build-Nummer der Command-line tools: https://developer.android.com/studio#command-line-tools-only
DEV_DIR="$HOME/dev"
ANDROID_SDK_ROOT="$HOME/Android/Sdk"

sudo apt-get update -qq
sudo apt-get install -y -qq curl git unzip xz-utils zip libglu1-mesa openjdk-17-jdk adb

# --- Flutter ---
mkdir -p "$DEV_DIR"
if [ ! -x "$DEV_DIR/flutter/bin/flutter" ]; then
  curl -fL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    -o /tmp/flutter.tar.xz
  tar -xJf /tmp/flutter.tar.xz -C "$DEV_DIR"
  rm -f /tmp/flutter.tar.xz
fi

# --- Android SDK (Command-line tools, ohne Android Studio) ---
mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"
if [ ! -d "$ANDROID_SDK_ROOT/cmdline-tools/latest" ]; then
  curl -fL "https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS}_latest.zip" -o /tmp/cmdline-tools.zip
  unzip -q /tmp/cmdline-tools.zip -d "$ANDROID_SDK_ROOT/cmdline-tools"
  mv "$ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools" "$ANDROID_SDK_ROOT/cmdline-tools/latest"
  rm -f /tmp/cmdline-tools.zip
fi

# --- PATH / Umgebung ---
if ! grep -q 'dev/flutter/bin' "$HOME/.bashrc"; then
  cat >>"$HOME/.bashrc" <<'EOF'

# Flutter + Android SDK
export PATH="$HOME/dev/flutter/bin:$PATH"
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"
EOF
fi
export PATH="$DEV_DIR/flutter/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"
export ANDROID_SDK_ROOT ANDROID_HOME="$ANDROID_SDK_ROOT"

yes | sdkmanager --licenses >/dev/null || true
sdkmanager "platform-tools" "platforms;android-35" "build-tools;35.0.0"

flutter config --no-analytics --no-cli-animations --no-enable-web --no-enable-linux-desktop >/dev/null
flutter config --android-sdk "$ANDROID_SDK_ROOT" >/dev/null
flutter precache --android
yes | flutter doctor --android-licenses >/dev/null || true

echo
echo "Fertig. Neue Shell öffnen und prüfen mit: flutter doctor"
echo "Handy verbinden (Android 11+, Wireless Debugging aktiv):"
echo "  adb pair <IP>:<Pairing-Port>   # Code vom Handy eingeben"
echo "  adb connect <IP>:<Port>"
echo "  flutter devices"

# --- USB-Geräte in WSL2 (für Geräte ohne Wireless Debugging, z. B. älteres Samsung < Android 11) ---
# Unter Windows einmalig (PowerShell als Admin): winget install usbipd
# Dann je Gerät: usbipd list  →  usbipd bind --busid <BUSID>  →  usbipd attach --wsl --busid <BUSID>
# In WSL2 die udev-Regel unten sorgt dafür, dass adb ohne root aufs Gerät darf:
if [ ! -f /etc/udev/rules.d/51-android.rules ]; then
  echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="04e8", MODE="0666", GROUP="plugdev"' | sudo tee /etc/udev/rules.d/51-android.rules >/dev/null   # Samsung
  echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="2a70", MODE="0666", GROUP="plugdev"' | sudo tee -a /etc/udev/rules.d/51-android.rules >/dev/null # OnePlus
  sudo udevadm control --reload-rules || true
fi
echo "USB: Windows-seitig 'usbipd attach --wsl --busid <BUSID>', danach hier 'adb devices'."
