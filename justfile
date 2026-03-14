# ABOUTME: Build automation for ff2.
# ABOUTME: Provides commands for generating, building, testing, and running the app.

default: build

# Generate the Xcode project from project.yml
generate:
    xcodegen generate

# Build the app (regenerates project first)
build: generate
    xcodebuild -project ff2.xcodeproj -scheme ff2 -configuration Debug build

# Build release
build-release: generate
    xcodebuild -project ff2.xcodeproj -scheme ff2 -configuration Release build

# Run the app
run: build
    @open "$$(find ~/Library/Developer/Xcode/DerivedData -path '*/ff2-*/Build/Products/Debug/ff2.app' -type d | head -1)"

# Run tests
test: generate
    xcodebuild -project ff2.xcodeproj -scheme ff2Tests -configuration Debug test

# Clean build artifacts
clean:
    xcodebuild -project ff2.xcodeproj -scheme ff2 -configuration Debug clean
    rm -rf ~/Library/Developer/Xcode/DerivedData/ff2-*

# Rebuild ghostty xcframework from submodule
build-ghostty:
    cd ghostty && zig build -Demit-xcframework=true -Dxcframework-target=universal -Doptimize=ReleaseFast
