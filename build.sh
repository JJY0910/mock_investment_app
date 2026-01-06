#!/bin/bash
set -e

# Flutter SDK 다운로드 및 설치 (최초 1회만)
if [ ! -d "flutter" ]; then
  echo "Downloading Flutter SDK..."
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git
fi

export PATH=pwd/flutter/bin:$PATH

flutter config --no-analytics
flutter --version

flutter pub get

# Flutter Web Release Build
flutter build web --release --web-renderer canvaskit
