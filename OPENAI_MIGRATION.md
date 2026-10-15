# OpenAI migration validation (2026-10-14)

## Implemented on this branch
- Translation and writing improvement use gpt-6-luna through existing Chat Completions, explicitly setting reasoning_effort=none so temperature remains supported.

## Dependency review
Direct URLSession calls; no OpenAI SDK or remote Swift package dependency found in the project.

## Verification completed
Source scan of all Swift files and project/dependency files. Remote read-back of modified files matches prepared contents. Static checks confirm retired text IDs removed from changed code and provider-specific token parameters retained. No Swift/Xcode compiler or API test credentials were available; these are NOT compilation or live API tests.

## Required before merge/release
- Build Debug and Release in Xcode with existing dependency lockfile.
- Exercise translation, writing improvement, and interpreter flow with English, Chinese, mixed language, numbers, names, and long text. Verify meaning preservation, Simplified Chinese, temperature encoding, and nonempty responses.
- Independently regress both transcription methods and Apple/OpenAI playback.
- Inspect actual outbound JSON (without logging API keys), test missing key/model access, 400/401/429, timeout, cancellation, and empty/truncated output.
- Use representative samples to compare quality, latency and actual billed usage before production rollout. Do not infer quality from model names.
- Release the updated app to every device; changing GitHub alone does not update installed binaries.

## Separate audio migration still required
These are outside the October 14 text-model email, but separately deprecated:
- gpt-4o-mini-tts dated snapshots: January 6, 2027; recommended replacement gpt-realtime-2.1-mini. Resolve the unversioned alias with the account Models API. Do not insert the Realtime model into the existing /audio/speech MP3/AAC request without validating its API contract. Implement a separate Realtime audio adapter or use on-device speech where available.
- gpt-4o-mini-transcribe: February 26, 2027. Evaluate gpt-transcribe for recorded files using /audio/transcriptions; adapt language hints and JSON text/languages response instead of assuming the current text format. Test M4A, empty/noisy audio, multilingual detection and domain terminology.

Sources:
- https://developers.openai.com/api/docs/deprecations
- https://developers.openai.com/api/docs/models/gpt-6-luna
- https://developers.openai.com/api/docs/models/gpt-6-sol
- https://developers.openai.com/api/docs/guides/latest-model
- https://developers.openai.com/api/docs/guides/speech-to-text
