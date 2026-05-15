# App Store Review Notes

Samantha Translate provides real-time speech translation.

## Subscription

- Product ID: `samantha_translate_weekly`
- Subscription group: `samantha_translate_pro`
- Offer: 3-day free trial for eligible new subscribers
- Price target: US$4.99 per week
- Access is gated by StoreKit 2 current entitlements.

## Backend

The app does not include an OpenAI API key. It sends the verified StoreKit signed transaction payload to Supabase Edge Function `realtime-token`. The function verifies active subscription/trial status, applies usage limits, and returns only a short-lived OpenAI Realtime client secret.

## Privacy

The app does not store audio, transcripts, or translation history. Audio is streamed only for real-time translation. Supabase stores operational subscription records: original transaction id, product id, status, expiration, environment, token request count, and timestamps.

## Review Account

No login account is required. Use StoreKit sandbox purchase flow to start the free trial.

