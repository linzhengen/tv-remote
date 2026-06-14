#!/bin/bash
set -euo pipefail

# iOS アプリ再インストールスクリプト
# flutter run --release を実行し、Xcode の自動署名により新しい
# プロビジョニングプロファイル（有効期限7日間）を発行して端末に再インストールする。
#
# 使用方法:
#   bash scripts/reinstall.sh               # 自動検出した端末にインストール
#   bash scripts/reinstall.sh <device_id>    # 指定した端末にインストール

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

DEVICE_ARG=""
if [ $# -ge 1 ]; then
    DEVICE_ARG="-d $1"
fi

echo "==> Building and installing tv-remote (release mode)..."
flutter run --release $DEVICE_ARG

echo ""
echo "Done! The app should now be installed on your device."
echo "Note: With a free Apple Developer account, the provisioning profile"
echo "will expire in 7 days. Re-run this script to reinstall."
