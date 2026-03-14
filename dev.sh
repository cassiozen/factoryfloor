#!/usr/bin/env bash
# ABOUTME: Dev script for building and running ff2.
# ABOUTME: Usage: ./dev.sh [command] [args]

set -e

# Resolve a path to absolute
resolve_dir() {
  if [ -n "$1" ]; then
    cd "$1" 2>/dev/null && pwd
  fi
}

case "${1:-run}" in
  build)
    xcodegen generate
    xcodebuild -project ff2.xcodeproj -scheme ff2 -configuration Debug build
    ;;
  test)
    xcodegen generate
    xcodebuild -project ff2.xcodeproj -scheme ff2Tests -configuration Debug test
    ;;
  run)
    shift 2>/dev/null || true
    DIR=$(resolve_dir "${1:-.}")
    open "ff2://$DIR"
    ;;
  br)
    shift 2>/dev/null || true
    DIR=$(resolve_dir "${1:-.}")
    xcodegen generate
    xcodebuild -project ff2.xcodeproj -scheme ff2 -configuration Debug build
    pkill -f "ff2.app/Contents/MacOS/ff2" 2>/dev/null || true
    sleep 0.5
    open "ff2://$DIR"
    ;;
  clean)
    xcodebuild -project ff2.xcodeproj -scheme ff2 -configuration Debug clean 2>/dev/null || true
    rm -rf ~/Library/Developer/Xcode/DerivedData/ff2-*
    ;;
  *)
    echo "Usage: ./dev.sh [build|test|run|br|clean] [directory]"
    echo ""
    echo "  build    Build the app"
    echo "  test     Run tests"
    echo "  run      Run the app (default), optionally with a directory"
    echo "  br       Build and run"
    echo "  clean    Clean build artifacts"
    ;;
esac
