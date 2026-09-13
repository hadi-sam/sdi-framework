# Discovery — Mobile app

Type-specific themes for native mobile apps (React Native, Flutter, native iOS/Android). Load alongside `references/discovery-themes.md`.

## ⚡ 1. Platform and runtime

What you're shipping and to whom.

Typical questions:
- iOS, Android, both at MVP, or one first?
- React Native, Flutter, Expo, native (Swift/Kotlin)?
- Minimum OS versions supported?
- Tablet support — yes/no, with adaptive layouts?
- Web companion — same codebase via React Native Web / Flutter Web, or separate?

## ⚡ 2. Distribution and stores

Often more friction than the code itself.

Typical questions:
- App Store + Google Play, or also enterprise/MDM/sideload (Android)?
- TestFlight / Play Internal Testing / Firebase App Distribution for beta?
- Code signing, certificates — managed by Expo/EAS, fastlane, manual?
- Update strategy — store releases, OTA (CodePush, Expo Updates), or both?
- Store listing assets — screenshots, descriptions, privacy nutrition labels?

## ⚡ 3. Backend and data sync

Mobile apps live in unstable network conditions.

Typical questions:
- Backend type — your own API, BaaS (Supabase/Firebase/Amplify), or both?
- Auth — email/pw, social, biometric, anonymous?
- Offline support — required, partial, or online-only acceptable?
- Sync strategy if offline — last-write-wins, CRDT, queued mutations with conflict UI?
- Data freshness — what's "fresh enough" per screen?

## 4. Native capabilities

Where mobile differs from web.

Typical questions:
- Camera, photo library, location, contacts, calendar?
- Push notifications — part of an approved flow or deferred/absent? If approved, with what targeting?
- Background tasks — periodic sync, location updates, geofencing?
- Deep links / universal links / app clips?
- Biometric auth (Face ID, Touch ID, fingerprint)?
- File system access — share extensions, document picker?

## 5. Push notifications

Use this theme only when notifications are part of an approved flow; otherwise omit it from requirements and architecture.

Typical questions:
- Provider — Apple Push, FCM, OneSignal, Pusher, Expo Notifications?
- Triggers — server-side, scheduled, event-driven?
- Targeting — per-user, segment, broadcast?
- In-app notification UX (foreground vs background handling)?
- Permission UX — when/how is permission requested?
- Rich notifications — images, action buttons, custom UI?

## 6. State management and persistence

Mobile state is heavier than web because of session continuity expectations.

Typical questions:
- Local state library — Redux, Zustand, MobX, Riverpod, BLoC?
- Persistence — AsyncStorage, MMKV, WatermelonDB, SQLite, Realm?
- Session continuity — app resumes exactly where user left, or returns to home?
- Hydration strategy on cold start?

## 7. Performance

Mobile is unforgiving on perf.

Typical questions:
- Cold start budget (target < 2s, hard ceiling)?
- Frame rate target (60fps is the floor)?
- Memory ceiling on lower-tier devices?
- Bundle size budget (initial download)?
- Image optimization — lazy load, downscale to viewport?

## 8. Analytics and crash reporting

Different from web in implementation if not in concept.

Typical questions:
- Analytics — Mixpanel, Amplitude, Firebase, PostHog, custom?
- Crash reporting — Sentry, Bugsnag, Firebase Crashlytics?
- Funnel tracking — onboarding, key actions?
- Privacy posture — App Store privacy labels, ATT prompt for iOS?

## 9. Privacy and store compliance

Easily underestimated until rejection.

Typical questions:
- Apple privacy nutrition labels — what data is collected, for what purpose?
- App Tracking Transparency (iOS) — required prompts?
- Google Data Safety section — equivalent disclosure?
- Permission justification strings (iOS Info.plist requires reason for each)?

## How to use

1. Themes 1, 2, 3 are foundational — without these, the app's shape is unclear.
2. Explore Theme 5 (push) only for an approved notification flow; if it is absent or deferred, do not turn it into a requirement.
3. Theme 7 (perf) and Theme 9 (privacy/compliance) are frequently deferred and frequently regretted.
4. If the app is iOS-first, prioritize Theme 9 and the compliance implications of approved native capabilities early.
