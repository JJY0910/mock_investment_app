#!/usr/bin/env bash
set -e

# Flutter SDK 다운로드 (최초 1회)
if [ ! -d "flutter" ]; then
  echo "Downloading Flutter SDK..."
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git
fi

export PATH="C:\Users\abcde\.gemini\antigravity\scratch\mock_investment_app/flutter/bin:"

flutter config --no-analytics
flutter --version
flutter pub get

# Flutter 3.38.x 기준: --web-renderer 옵션 없음
flutter build web --release
