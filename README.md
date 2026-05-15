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

- `SamanthaTranslate/` - SwiftUI iOS app
- `supabase/` - Edge Functions and database migration
- `web/` - Vercel support/privacy site
- `AppStore/` - metadata and screenshot output
- `docs/` - review notes and privacy answers

## Local iOS build

```bash
xcodegen generate
xcodebuild -project SamanthaTranslate.xcodeproj -scheme SamanthaTranslate -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Supabase secrets

Set these in Supabase, never in the iOS app:

```bash
supabase secrets set OPENAI_API_KEY=YOUR_OPENAI_API_KEY
supabase secrets set OPENAI_REALTIME_MODEL=gpt-realtime
supabase secrets set OPENAI_REALTIME_VOICE=marin
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
