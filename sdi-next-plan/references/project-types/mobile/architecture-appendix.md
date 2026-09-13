# Architecture Appendix — Mobile app

Insert these sections into ARCHITECTURE.md at §2 ("Type-specific architecture") of the core architecture template.

## §2.1 Platform and runtime

State the platform commitment and rationale:

- **Platforms:** iOS, Android, both at MVP, or one first
- **Framework:** React Native + Expo / React Native bare / Flutter / Native (Swift + Kotlin) — with rationale (team skill, native API needs, target audience)
- **Min OS versions:** iOS X+, Android API level Y+
- **Form factors:** phone only, phone + tablet, phone + foldable
- **Web companion:** none / React Native Web / shared codebase / separate project

## §2.2 Backend integration

- **Backend:** [own API at endpoint X] / [Supabase/Firebase/Amplify] / [hybrid]
- **Auth:** [email/pw + social] / [magic link] / [biometric local + server-issued JWT]
- **API client:** [native fetch + custom wrapper] / [Apollo (GraphQL)] / [SDK from BaaS]
- **Network resilience:** add retry or an offline queue only when the approved flow's delivery/offline contract requires it

## §2.3 Offline and sync

State posture explicitly even if online-only:

- **Posture:** [Online-only with offline error states] / [Cache-then-fetch (read-only offline)] / [Full offline with sync] / [CRDT-based]
- **Local store:** [AsyncStorage / MMKV / SQLite / WatermelonDB / Realm]
- **Sync mechanism:** [periodic poll] / [push-based via websocket] / [server-sent events] / [delta sync on reopen]
- **Conflict resolution:** last-write-wins / merge-with-rules / surface to user

## §2.4 Push notifications

Include this section only when an approved flow or contract includes push notifications; otherwise omit it. Resolve only the options that flow needs:

- **Provider:** [APNs + FCM direct] / [OneSignal] / [Expo Notifications] / [Firebase Cloud Messaging]
- **Token registration:** [after permission grant] / [other approved trigger]; [refresh handling] / [none]
- **Server-side trigger:** [approved backend events] / [schedule] / [none]
- **Permission UX:** [contextual OS prompt] / [soft-ask then OS prompt]
- **Foreground vs background handling:** [in-app presentation] / [OS surface] / [suppressed] for each relevant app state

## §2.5 Native capability usage

For each approved capability; omit unused example rows:

| Capability | Used for | Permission strategy | iOS Info.plist key | Android manifest |
|---|---|---|---|---|
| Camera | [profile photo] | request when feature accessed | NSCameraUsageDescription | CAMERA |
| Location | [nearby search] | request with rationale screen | NSLocationWhenInUseUsageDescription | ACCESS_FINE_LOCATION |
| Notifications | [reminders] | [soft-ask + OS prompt] / [contextual OS prompt] | n/a | POST_NOTIFICATIONS |
| ... | | | | |

## §2.6 Deep links and universal links

- **iOS Universal Links:** apple-app-site-association configured, handler in scene delegate / RN linking
- **Android App Links:** assetlinks.json configured, intent filters in manifest
- **Custom URL scheme:** for fallbacks and dev (`myapp://`)
- **Routing:** how a deep link resolves to a screen — typed route map

## §2.7 State management

- **Local UI state:** [framework-native (useState, signals)] / [Zustand / Redux / MobX / Riverpod]
- **Server cache:** [React Query / SWR / Apollo cache] / [framework state]
- **Persistent app state:** what survives kill/restart (auth tokens, user preferences, drafts)
- **Hydration on cold start:** what loads from disk before first render

## §2.8 Performance posture

- **Cold start target:** < 2s on mid-tier device
- **Frame rate floor:** 60fps for animations and scroll
- **Bundle size:** initial download under N MB
- **Image strategy:** local assets at 1x/2x/3x; remote images responsively sized via CDN
- **Lists:** virtualized for any list potentially > 50 items (FlashList, Flutter ListView.builder)

## §2.9 Analytics, crash, and observability (select only required surfaces)

- **Analytics:** [none] / [provider + only events required by an approved product criterion]
- **Crash reporting:** [none] / [provider + symbol upload when production recovery requires it]
- **Performance traces:** only flows covered by an approved performance target
- **Privacy:** ATT prompt timing on iOS, opt-in vs opt-out posture, store privacy labels

## §2.10 Distribution

- **Build & sign:** [Expo EAS] / [fastlane] / [Xcode Cloud + GitHub Actions]
- **Beta:** [TestFlight + Play Internal] / [Firebase App Distribution]
- **Update channel:** [Store releases only] / [Store + OTA (Expo Updates / CodePush)] — with policy on what can ship via OTA (UI/copy yes; native code no)
- **Versioning:** semver in JS bundle, build numbers monotonic, release notes per submission
