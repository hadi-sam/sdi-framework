# PROJECT_STRUCTURE Template — Mobile app

Repo layout for a mobile app. Adapts to chosen framework (React Native/Expo, Flutter, native).

Target length: 200–300 lines.

## Structure

```markdown
# [Product] — Project Structure & Conventions

> Folder layout and conventions for the [React Native + Expo / Flutter / Native iOS+Android] app. Read by the coding agent as context when generating code.

## Top-Level Layout

\`\`\`
[repo-root]/
├── .github/                # CI workflows
├── src/                    # (or lib/ in Flutter)
│   ├── app/                # navigation entry, root providers
│   ├── screens/            # one folder per screen
│   ├── components/         # reusable UI
│   ├── navigation/         # stack/tab/drawer config
│   ├── api/                # HTTP/GraphQL client + endpoint wrappers
│   ├── stores/             # state management (Zustand/Redux/Riverpod)
│   ├── persistence/        # AsyncStorage/MMKV/SQLite wrappers
│   ├── notifications/      # push registration, handlers, preference UI
│   ├── deep-links/         # link parsing → route mapping
│   ├── analytics/          # event taxonomy + tracker
│   ├── theme/              # tokens, typography, dark mode
│   └── utils/              # cross-cutting helpers
├── assets/                 # images, fonts, icons
├── tests/
├── ios/                    # native iOS project (RN bare)
├── android/                # native Android project (RN bare)
├── docs/
└── [config files]
\`\`\`

## src/screens/ — Screens

\`\`\`
[tree — one folder per screen with screen file, child components, hooks specific to the screen]
\`\`\`

### Screen conventions

- One folder per screen: `screens/Home/`, `screens/ProfileEdit/`.
- Each folder contains the screen component, screen-specific hooks, and any sub-components.
- Screen receives navigation props as typed; never imports navigator directly.
- Data fetching uses `src/api/` — no inline fetches.

## src/navigation/ — Routing

\`\`\`
[tree — root navigator, stack/tab definitions, route type definitions]
\`\`\`

### Navigation conventions

- Route types are declared centrally; screens read typed params.
- Deep link route map is colocated with navigator config.
- Modal vs push transitions are explicit per route.

## src/api/ — Network

\`\`\`
[tree — client.ts, endpoints organized by resource]
\`\`\`

### API conventions

- Use a single client wrapper around fetch/Apollo only when auth or repeated response behavior in the approved flow/contract justifies it; app code then uses the wrapper instead of calling fetch directly.
- When present, the wrapper centralizes the approved shared behavior; add retry, request IDs or offline queue only when the real flow/contract requires them.
- Errors are typed (NetworkError, AuthError, ServerError).

## src/stores/ — State

\`\`\`
[tree per store domain]
\`\`\`

### State conventions

- Each store has a clear domain — auth store, settings store, draft store.
- Selectors are exported for reuse; components don't reach into raw state.
- Persisted slices listed explicitly.

## src/persistence/

\`\`\`
[tree — wrappers for AsyncStorage/MMKV/SQLite]
\`\`\`

### Persistence conventions

- App code uses domain methods (`saveDraft`, `loadAuthToken`), not raw KV calls.
- PII (tokens, biometric refs) goes through secure storage (Keychain / Keystore).

## src/notifications/

\`\`\`
[tree — registration, handler, preference UI]
\`\`\`

### Notification conventions

- Permission request is gated by an in-app rationale screen, not auto-prompted on first launch.
- Add retries for transient token-registration failures and automatic re-registration of refreshed tokens only when the approved notification flow/contract requires those behaviors.
- Foreground notification handling renders an in-app toast; background goes to OS surface.

## src/deep-links/

\`\`\`
[tree — parser, route resolver, fallbacks]
\`\`\`

## src/analytics/

\`\`\`
[tree — events.ts (taxonomy), tracker.ts (wrapper)]
\`\`\`

### Analytics conventions

- Use `tracker.ts` only when an approved analytics taxonomy/shared consent boundary exists.
- Event names follow a fixed taxonomy file; no ad-hoc strings.
- PII is never in event properties.

## src/theme/

\`\`\`
[tree — tokens, typography, light/dark]
\`\`\`

## Coding Conventions

### Framework idioms
- [React Native: function components only, hooks for everything, no class components]
- [Flutter: stateless widgets where possible, state hoisted to provider/Riverpod]
- [Native iOS: Swift + SwiftUI; UIKit only when SwiftUI doesn't fit]

### TypeScript / language
- Strict mode. No `any`. Network responses typed at the boundary.

### Lists and performance
- Any list > 20 items uses virtualization (FlashList, FlatList with windowing, ListView.builder).
- Images explicitly sized; remote images go through a CDN with responsive variants.

### Accessibility
- All interactive elements have accessibility labels.
- Color is never the only signal.
- Respects reduce-motion and large-text system settings.

### Testing
- Add unit/component/E2E tests only for material silent harm or an approved acceptance criterion; choose the smallest level that proves the risky flow.

### Distribution
- iOS build via [Expo EAS / fastlane / Xcode Cloud]; outputs ipa with provisioning profile.
- Android build outputs aab for Play Store.
- OTA-eligible changes: JS-only (no native module changes); enforced in PR checklist.

### Commits & Branches
- [conventional commits, branch naming]

### Environment Variables
- API endpoints (dev/staging/prod).
- Analytics keys, push provider keys.
- Feature flags resolved at app start.

## Coding agent kickoff prompt template

[End-of-doc prompt template — what the user pastes into the coding agent on day one.]
```

## Writing tips

- **Screens are folders, not single files.** Once a screen has hooks + sub-components, splitting is mandatory.
- **API boundary follows shared contracts.** Use a client wrapper only when auth or repeated response behavior justifies it.
- **Permissions need rationale UX.** Native prompts are unforgiving — soft-ask first.
- **OTA policy must be explicit.** Without it, native breakage will eventually be shipped via OTA.
