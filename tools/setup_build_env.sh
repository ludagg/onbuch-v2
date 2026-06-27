#!/usr/bin/env bash
# Installe la chaîne de build OnBuch (Shorebird + Flutter + SDK Android) dans
# l'environnement d'exécution Claude Code (remote, éphémère). À relancer au
# début d'une session qui doit builder/patcher.
#
# Particularité de cet environnement : la sortie HTTPS passe par un proxy
# (HTTPS_PROXY) et le Git est restreint au repo en scope. Les clones externes
# (Shorebird, Flutter) doivent donc passer par le proxy de sortie via un
# gitconfig dédié (sans l'« insteadOf » qui route vers l'endpoint scoped).
#
# Usage : bash tools/setup_build_env.sh
set -e

PROXY="${HTTPS_PROXY:-http://127.0.0.1:38575}"
CA="/root/.ccr/ca-bundle.crt"
WORK="${BUILD_WORK:-/tmp/onbuch-build}"
mkdir -p "$WORK"

# gitconfig de build : route github via le proxy de sortie (clones externes OK).
BUILD_GITCONFIG="$WORK/build.gitconfig"
cat > "$BUILD_GITCONFIG" <<EOF
[http]
    proxy = $PROXY
    sslCAInfo = $CA
EOF

echo "→ [1/3] Shorebird (clone via proxy de sortie)…"
if [ ! -x "$HOME/.shorebird/bin/shorebird" ]; then
  GIT_CONFIG_GLOBAL="$BUILD_GITCONFIG" GIT_CONFIG_SYSTEM=/dev/null \
    git clone --branch stable https://github.com/shorebirdtech/shorebird "$HOME/.shorebird"
fi
export PATH="$HOME/.shorebird/bin:$PATH"
GIT_CONFIG_GLOBAL="$BUILD_GITCONFIG" GIT_CONFIG_SYSTEM=/dev/null shorebird --version

echo "→ [2/3] SDK Android (cmdline-tools + platforms + build-tools + NDK)…"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-/root/android-sdk}"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
if [ ! -x "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" ]; then
  mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"
  curl -sLo "$WORK/cmdtools.zip" \
    "https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip"
  rm -rf "$WORK/cmdline-tools"
  unzip -q "$WORK/cmdtools.zip" -d "$WORK"
  mv "$WORK/cmdline-tools" "$ANDROID_SDK_ROOT/cmdline-tools/latest"
fi
SDK="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager"
yes | "$SDK" --sdk_root="$ANDROID_SDK_ROOT" --licenses >/dev/null 2>&1 || true
"$SDK" --sdk_root="$ANDROID_SDK_ROOT" \
  "platform-tools" "platforms;android-35" "platforms;android-36" \
  "build-tools;35.0.1" "build-tools;36.0.0" "ndk;26.3.11579264" "cmake;3.22.1" >/dev/null

echo "→ [3/3] Variables d'environnement à exporter pour builder :"
FL=$(ls -d "$HOME/.shorebird/bin/cache/flutter/"*/ 2>/dev/null | head -1)
cat <<EOF

  export ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT" ANDROID_HOME="$ANDROID_SDK_ROOT"
  export GIT_CONFIG_GLOBAL="$BUILD_GITCONFIG" GIT_CONFIG_SYSTEM=/dev/null
  export PATH="\$HOME/.shorebird/bin:${FL}bin:\$ANDROID_SDK_ROOT/platform-tools:\$PATH"
  export SHOREBIRD_TOKEN="<token>"   # jamais commité

Signature de release : déposer android/key.properties (storePassword, keyPassword,
keyAlias, storeFile) + le keystore dans android/app/ — tous deux gitignorés.

Release  : shorebird release android -- --no-tree-shake-icons
Patch    : shorebird patch android --release-version=<x.y.z+n> -- --no-tree-shake-icons
APK seul : flutter build apk --release --no-tree-shake-icons
EOF
echo "Terminé."
