---
name: sk-infisical-sdk-overview
description: >
  Use when the user asks to work with the @infisical/sdk Node package (v5.x) — fetch secrets
  programmatically, initialize an SDK client, set up universal auth, call getSecret or listSecrets,
  or troubleshoot SDK connectivity. Also use when the user says "fetch secrets from Infisical in my
  app", "on-demand secret fetch", prefers programmatic over CLI env-injection, or wants to understand
  the Analygo @analygo/env wrapper. Use even when the user mentions "SDK" or "Infisical" in a Node.js
  code context, since the SDK v5 API changed substantially from earlier versions.
---

# sk-infisical-sdk-overview — @infisical/sdk v5.x for Node.js

The Infisical Node.js SDK (v5.x, class `InfisicalSDK`) lets application code fetch secrets from
Infisical at call time. This is the ON-DEMAND path. The Analygo monorepo wraps it in
`@analygo/env/vault.ts` (`getSecret`, `getSecretsByFolder`, `resolveSecretReference`).

## Auth methods

Every SDK client authenticates as a **machine identity** — never a user login or personal token.

**Universal Auth** (use this): clientId + clientSecret. Non-expiring. Portable. Works everywhere.
**Platform-native auth**: Kubernetes service account, AWS IAM, etc. Prefer when running on that platform.

The two auth paths in the Analygo infra:

| Path | Credential | When used |
|------|-----------|-----------|
| **CLI boot** | `INFISICAL_SERVICE_TOKEN` (scoped JWT) | Process startup. `infisical run --token …` wraps the process, pre-populates env. |
| **SDK runtime** | `INFISICAL_CLIENT_ID` + `INFISICAL_CLIENT_SECRET` (universalAuth) | On-demand at runtime. `@analygo/env/vault.ts` handles auth lazily. |

The SDK path cannot replace the CLI path — CLI must run before the process boots.

## Procedures

### [ ] Step 1: Initialize the SDK

```ts
import { InfisicalSDK } from "@infisical/sdk";

const client = new InfisicalSDK({
  siteUrl: "https://infisical.analygo.co",     // NO /api suffix — SDK adds it internally
});
```

- `siteUrl` defaults to `https://app.infisical.com` — override for self-hosted.
- The SDK constructs API paths as `{siteUrl}/api/v1/auth/...` and `{siteUrl}/api/v3/secrets/raw`.
- **`siteUrl` must NOT end in `/api`** — otherwise the SDK would call `/api/api/v1/...` (double path).

### [ ] Step 2: Authenticate (universal auth)

```ts
await client.auth().universalAuth.login({
  clientId: "dfa58c50-...",
  clientSecret: "059dd5ea...",
});
```

- The SDK mints and caches an access token. It auto-refreshes on 401/403.
- Credentials come from `process.env`, falling back to `~/.analygo/env.shared`.
- The `@analygo/env/vault.ts` `vaultClient()` function does this lazily: first call initializes,
  subsequent calls reuse the memoized client.

### [ ] Step 3: Fetch a single secret

```ts
const secret = await client.secrets().getSecret({
  environment: "prod",
  projectId: "6471384a-5404-4a63-9ac3-090f1264bb37",
  secretPath: "/",                                // folder path, defaults to root
  secretName: "ANTHROPIC_API_KEY",
  viewSecretValue: true,                          // return the value, not metadata
  expandSecretReferences: true,                   // resolve ${...} references
});
```

- Returns an object with `secretValue` (or `secret.secretValue` depending on version).
- `@analygo/env/vault.ts` wraps this in `getSecret(key, opts)` with Zod-validated envelopes.

### [ ] Step 4: List all secrets in a folder

```ts
const secrets = await client.secrets().listSecrets({
  environment: "prod",
  projectId: "6471384a-5404-4a63-9ac3-090f1264bb37",
  secretPath: "/hatchet",
  expandSecretReferences: true,
  includeImports: true,
  viewSecretValue: true,
});
```

- Returns an array of `{ secretKey, secretValue, secretPath, environment }`.
- `@analygo/env/vault.ts` wraps this in `getSecretsByFolder(folder, opts)`.

### [ ] Step 5: Use the Analygo wrapper (preferred)

Instead of raw SDK calls, use the Analygo wrapper for consistency:

```ts
import { getSecret, getSecretsByFolder, resolveSecretReference } from "@analygo/env/vault";

const s = await getSecret("ANTHROPIC_API_KEY", { env: "prod", path: "/models" });
// Returns a SecretValue envelope: { key, value, env, path, fetchedAt }
// On unreachable vault: value is "" — caller decides severity.

const folder = await getSecretsByFolder("/hatchet", { env: "prod", expand: true });
// Returns SecretValue[] — empty array on unreachable vault.
```

## Gotchas

- **The SDK class is `InfisicalSDK`, NOT `InfisicalClient`.** Earlier docs used `InfisicalClient`.
  v5.x renamed the class. If you see documentation mentioning `InfisicalClient`, it's for an older
  version — look for docs matching v5+.
- **`siteUrl` must NOT end with `/api`.** The SDK appends `/api` to all request paths. If you pass
  `https://infisical.analygo.co/api`, it calls `https://infisical.analygo.co/api/api/v1/auth/…`
  (double `/api`). The `@analygo/env/vault.ts` wrapper already strips trailing `/api` with `.replace()`.
- **`.secrets()` is a method call, not a property.** Always `client.secrets().getSecret()` not
  `client.secrets.getSecret()`. The `.secrets()` and `.auth()` methods return sub-clients.
- **The SDK does NOT auto-reload secrets on a timer.** Call `getSecret()` / `listSecrets()` again
  to get updated values. Cache expiry is request-failure-based (falls back to cached on 4xx/5xx).
- **If no cached value exists AND the vault is unreachable, the SDK returns the process env value.**
  In `@analygo/env/vault.ts`, failure returns an empty envelope (`{ value: "" }`) — callers decide
  whether to hard-fail or continue.

## When NOT to use the SDK

- The app just needs env vars at startup → use `infisical run -- <command>` (CLI injection).
- A CI pipeline needs secrets → use `infisical run` in the CI step.
- You need to manage secrets (create, update, delete) → use the CLI or Infisical dashboard; SDKs are read-mostly.
- An AI agent needs credentials → use Agent Vault, not the SDK (the SDK exposes raw values).

## References

- `@analygo/env/vault.ts` — the Analygo wrapper in `packages/env/src/vault.ts`
- `sk-infisical-cli` — the CLI boot path (service token, `infisical run`, Unix Domain Socket agent)
- `sk-infisical-service` — the Infisical Service SDK Node helper (if this exists in the skills dir)