# Crash Reporting

## Why

Factory Floor embeds a C library (ghostty/libghostty) via Metal GPU
rendering, manages multiple concurrent terminal processes, and does
heavy AppKit/SwiftUI interop. Crashes in production are inevitable
but invisible without telemetry. Users rarely file bug reports for
crashes; they just relaunch.

## What to capture

- Swift/ObjC exceptions and signal crashes (SIGSEGV, SIGBUS, SIGABRT)
- C-level crashes in libghostty (these bypass Swift's exception handling)
- Hang detection (main thread blocked for >5 seconds)
- Non-fatal errors (ghostty_surface_new returning nil, file persistence failures)
- Breadcrumbs: last few user actions before crash (tab switch, workstream create, etc.)

## Options

### 1. Sentry (recommended)

The most mature crash reporting SDK for macOS native apps.

**Pros:**
- Supports Swift, ObjC, and C crashes (critical for libghostty)
- Symbolication for release builds (dSYM upload)
- Breadcrumbs, user context, tags
- Session tracking, release health dashboard
- Free tier: 5K errors/month, 10K transactions/month
- Self-hosted option available
- Privacy: data processing in EU available

**Cons:**
- Adds ~2MB to app bundle
- Requires account setup and DSN configuration
- Network calls on crash (queued and sent on next launch if offline)

**Integration:**
```yaml
# project.yml
packages:
  Sentry:
    url: https://github.com/getsentry/sentry-cocoa
    from: "8.0.0"
```

```swift
// FF2App.swift init
import Sentry

SentrySDK.start { options in
    options.dsn = "https://key@sentry.io/project"
    options.enableCrashHandler = true
    options.enableAppHangTracking = true
    options.appHangTimeoutInterval = 5
    options.attachScreenshot = false // privacy
    options.tracesSampleRate = 0.1
    #if DEBUG
    options.enabled = false
    #endif
}
```

**dSYM upload in CI:**
```bash
# In release.yml after xcodebuild
sentry-cli upload-dif --include-sources \
  build/release/FactoryFloor.app.dSYM
```

**Estimated effort:** Half a day.

### 2. Firebase Crashlytics

Google's crash reporting, widely used on iOS.

**Pros:**
- Free, no usage limits
- Good symbolication
- Real-time alerts

**Cons:**
- Requires Google account and Firebase project
- Heavier SDK (Firebase ecosystem)
- Less mature macOS support than iOS
- Google data handling (may concern privacy-focused users)
- No C crash support out of the box (would miss libghostty crashes)

**Not recommended** due to weak C crash support and heavier dependency.

### 3. PLCrashReporter (DIY)

Low-level crash reporting library. Powers many commercial solutions.

**Pros:**
- Open source (Microsoft, BSD license)
- Captures C-level crashes
- No external service dependency
- Full control over data

**Cons:**
- Raw crash logs, no dashboard
- Need to build upload, symbolication, and alerting yourself
- Significant maintenance burden

**Not recommended** unless there's a strong reason to avoid third-party services.

### 4. Apple's built-in crash reports

Users can share crash reports via macOS Feedback Assistant or the
crash log in Console.app (~/.Library/Logs/DiagnosticReports/).

**Pros:**
- Zero integration effort
- Already works

**Cons:**
- Requires users to manually find and share reports
- No aggregation, no alerts, no trends
- Basically useless for proactive crash detection

## Privacy considerations

Factory Floor handles sensitive data (project paths, branch names,
file contents in terminals). The crash reporter must:

- Never capture terminal content or screenshots
- Strip file paths from breadcrumbs (or hash them)
- Respect a user opt-out setting (add to Settings > Danger Zone)
- Document what's collected in the privacy policy

## Recommendation

**Sentry** is the clear winner for Factory Floor:
- Catches C crashes from libghostty (critical)
- Free tier is generous for a developer tool
- Half-day integration
- EU data residency available
- Can be gated behind a setting for users who want to opt out

## Implementation plan

1. Create Sentry project (sentry.io or self-hosted)
2. Add sentry-cocoa package to project.yml
3. Initialize in FF2App with crash handler and app hang tracking
4. Disable in DEBUG builds
5. Add dSYM upload step to CI release workflow
6. Add "Send crash reports" toggle to Settings (default: on)
7. Update privacy policy on the website
8. Add breadcrumbs for key user actions (workstream create/archive,
   tab switch, script run, terminal respawn)
