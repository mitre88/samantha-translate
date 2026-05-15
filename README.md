# Samantha Translate

Premium iOS voice translator with a minimal SwiftUI interface, StoreKit subscription gating, Supabase token broker, and OpenAI Realtime speech translation.

## Product

- App name: Samantha Translate
- Bundle ID: `com.alexmitre.samanthatranslate`
- Product ID: `samantha_translate_weekly`
- Trial: 3 days free, then US$4.99/week
- Supported UI languages: English, Spanish, French, Simplified Chinese, Japanese
- Data policy: no stored audio, transcripts, or translation history

## Structure

- `SamanthaTranslate/` - SwiftUI iOS app with native WebRTC Realtime audio
- `supabase/` - Edge Functions and database migration
- `web/` - Vercel support/privacy site
- `AppStore/` - metadata and screenshot output
- `docs/` - review notes and privacy answers

## Local iOS build

```bash
xcodegen generate
xcodebuild -project SamanthaTranslate.xcodeproj -scheme SamanthaTranslate -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## StoreKit testing

The shared Xcode scheme uses `StoreKit/SamanthaTranslate.storekit` for local purchase testing. Run the app from Xcode with the `SamanthaTranslate` scheme and the native Apple subscription sheet can start the 3-day trial without a real App Store purchase.

For end-to-end entitlement testing against Apple's sandbox, install the App Store Connect build through TestFlight or use a Sandbox Apple Account. Sandbox purchases are not charged, but they require an Apple testing environment; a normal App Store account in a development build can show environment permission errors.

## Supabase secrets

Set these in Supabase, never in the iOS app:

```bash
supabase secrets set OPENAI_API_KEY=YOUR_OPENAI_API_KEY
supabase secrets set OPENAI_REALTIME_TRANSLATE_MODEL=gpt-realtime-translate
supabase secrets set OPENAI_CLIENT_SECRET_TTL_SECONDS=120
```

## Web

Production support site: https://samantha-translate-mitre88.vercel.app

```bash
cd web
npm install
npm run build
```

## Release checklist

1. Configure Apple Developer team in `project.yml`.
2. Create App Store app and subscription group/product in App Store Connect.
3. Deploy Supabase migration and Edge Functions.
4. Use the Vercel support site in App Store Connect metadata.
5. Generate screenshots from simulator and audit dimensions.
6. Archive/upload build and submit for review.
