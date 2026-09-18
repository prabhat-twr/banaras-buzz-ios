// Template only — this file IS committed, but is never referenced by the app's code (a
// different type name than the real Secrets.swift, so it never conflicts if both exist).
//
// To enable the real-AI path in the Kashi Assistant chat on your own machine:
//   1. Copy this file to Secrets.swift (same folder).
//   2. Rename `SecretsExample` to `Secrets` in your copy.
//   3. Paste your Gemini API key as the value of geminiAPIKey.
// Secrets.swift is listed in .gitignore, so your real key never gets committed. Leaving it
// absent (or blank) just means the chat falls back to the offline rule-based assistant.
enum SecretsExample {
    static let geminiAPIKey: String = ""
}
