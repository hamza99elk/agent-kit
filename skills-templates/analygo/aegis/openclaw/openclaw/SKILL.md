---
name: analygo-audit
description: "Trigger and monitor consent compliance audits via analygo platform and Aegis."
user-invocable: true
---

# Analygo Audit Skill

This skill enables OpenClaw to trigger consent compliance audits, monitor run status, and retrieve insight bundles with compliance findings and recommendations.

## Architecture

The skill interacts with two API systems:

1. **Platform API** (consent orchestration): Triggers audits and polls run status
2. **Aegis API** (audit intelligence): Retrieves synthesized insight bundles with compliance narratives

## Environment Variables

Required configuration (set in `~/.openclaw/openclaw.json` or environment):

```bash
PLATFORM_API_KEY=<your-platform-api-key>
PLATFORM_BASE_URL=https://platform.analygo.ai  # or http://localhost:8000 for dev
AEGIS_BASE_URL=http://localhost:8001  # or production Aegis URL
AEGIS_API_KEY=<aegis-api-key>  # optional, if Aegis requires auth
```

## API Endpoints

### 1. Trigger Audit (Platform)

**Endpoint:** `POST /consent/audit`  
**Authentication:** `X-API-Key` header with `PLATFORM_API_KEY`  
**Body:**

```json
{
  "site_url": "https://example.com",
  "mode": "consent_url",
  "skip_puppet": false,
  "browser_agent_model": "claude-3-5-sonnet-20240229"
}
```

**Response:**

```json
{
  "run_id": "run_abc123xyz"
}
```

### 2. Poll Run Status (Platform)

**Endpoint:** `GET /runs/{run_id}`  
**Authentication:** `X-API-Key` header with `PLATFORM_API_KEY`  
**Response:**

```json
{
  "run_id": "run_abc123xyz",
  "status": "running",
  "audit_type": "consent_audit",
  "created_at": "2026-04-17T10:00:00Z",
  "completed_at": null
}
```

**Status values:**
- `queued` — audit queued, not yet started
- `running` — audit in progress
- `success` — audit completed successfully
- `partial` — audit completed with partial results
- `failed` — audit failed

**Polling protocol:**
- Poll every 30 seconds until status is `success`, `partial`, or `failed`
- Do NOT poll more frequently than once every 30 seconds
- Maximum poll duration: 10 minutes (abort if run is still `running` after 10 minutes)

### 3. Retrieve InsightBundle (Aegis)

**Endpoint:** `GET /auditor/synthesis/{run_id}`  
**Authentication:** `X-API-Key` header with `AEGIS_API_KEY` (if required)  
**Response:**

```json
{
  "run_id": "run_abc123xyz",
  "generated_at": "2026-04-17T10:05:32Z",
  "severity": "high",
  "narrative": "The audit detected 3 consent violations on example.com...",
  "business_impact": "GDPR Art. 7 violation — potential regulatory fine up to €20M or 4% of global annual revenue",
  "recommended_action": "Immediately block premature tag firing before consent acceptance; implement consent wall; audit analytics configuration",
  "puppet_score": {
    "confidence": "high",
    "matched_events": ["add_to_cart", "begin_checkout"],
    "missing_events": ["purchase"],
    "unexpected_events": []
  },
  "coherence_report": {
    "coherence_score": 0.4,
    "violations": [
      {
        "kind": "premature_firing",
        "severity": "high",
        "message": "Google Analytics fired before consent acceptance",
        "tags": ["_ga", "_gid"]
      }
    ]
  },
  "research_queries": [
    "GDPR Art. 7 consent requirements",
    "Google Analytics GDPR compliance"
  ]
}
```

**Severity levels:**
- `critical` — immediate action required, severe compliance risk
- `high` — significant violation, regulatory exposure
- `medium` — compliance gap, should be addressed
- `low` — minor issue, best practice improvement
- `clean` — no violations detected

## Example Interactions

### Example 1: Trigger Audit and Summarize

**User:** "Audit shopify.com"

**OpenClaw response:**

1. Call `POST /consent/audit` with `{"site_url": "https://shopify.com"}`
2. Extract `run_id` from response
3. Poll `GET /runs/{run_id}` every 30 seconds until status is `success`, `partial`, or `failed`
4. If status is `success` or `partial`, call `GET /auditor/synthesis/{run_id}`
5. Format and return InsightBundle as message:

```
✅ Audit completed for shopify.com (run: run_abc123xyz)

Severity: HIGH
Business Impact: GDPR Art. 7 violation — potential regulatory fine up to €20M or 4% of global annual revenue

Narrative:
The audit detected 3 consent violations on shopify.com. Google Analytics fired before consent acceptance, violating GDPR Art. 7. Two additional tracking pixels (_fbp, _fbc) were set in the pre-consent phase without user authorization.

Recommended Action:
Immediately block premature tag firing before consent acceptance; implement consent wall; audit analytics configuration.

Violations:
- Premature firing: Google Analytics fired before consent acceptance (_ga, _gid)
- Premature firing: Facebook Pixel fired before consent acceptance (_fbp, _fbc)

Puppet Interaction:
- Confidence: high
- Matched events: add_to_cart, begin_checkout
- Missing events: purchase
```

### Example 2: Check Last Audit Result

**User:** "What did the last audit find for maxibeauty.ma?"

**OpenClaw response:**

1. Look up the most recent `run_id` for `maxibeauty.ma` (you may need to maintain a local cache of recent audits, or query the platform for runs filtered by site_url if that endpoint exists)
2. Call `GET /auditor/synthesis/{run_id}`
3. Format and return InsightBundle summary

### Example 3: Trigger Audit Without Puppet

**User:** "Audit example.com but skip the puppet interaction"

**OpenClaw response:**

1. Call `POST /consent/audit` with `{"site_url": "https://example.com", "skip_puppet": true}`
2. Poll and retrieve insights as in Example 1

## Stop Conditions (Safety Rules)

**NEVER:**
1. **Trigger more than one audit for the same URL within a 10-minute window** — audits are expensive and rate-limited; avoid duplicate runs
2. **Proceed to checkout payment during puppet interaction** — audits should NEVER complete actual purchases; puppet should stop at "begin_checkout" event
3. **Poll run status more frequently than once every 30 seconds** — respect rate limits
4. **Continue polling beyond 10 minutes** — abort and report "audit timed out" if run is still `running` after 10 minutes

**DO:**
1. Always confirm the site URL with the user before triggering an audit
2. Report partial results if status is `partial` (some evidence collected but not all phases completed)
3. Report failed audits with error details if status is `failed`
4. Cache run_ids locally with site_url for quick re-lookup (e.g., "What did the last audit find for X?")

## Error Handling

### Platform API Errors

- **401 Unauthorized:** `PLATFORM_API_KEY` is invalid or missing — prompt user to check config
- **422 Validation Error:** Invalid `site_url` or unsupported parameters — show validation message and ask user to correct
- **429 Rate Limit:** Too many requests — wait 60 seconds and retry once, then report to user
- **500 Server Error:** Platform internal error — report to user and suggest retrying later

### Aegis API Errors

- **404 Not Found:** No InsightBundle exists for the given `run_id` — this may happen if:
  - The run is still processing (status is `running` or `queued`) — continue polling platform
  - The run failed before synthesis — check platform run status for error details
  - The run_id is invalid — verify run_id with user
- **500 Server Error:** Aegis internal error — report to user

## Development and Testing

### Local Development

When testing locally, use:

```bash
PLATFORM_BASE_URL=http://localhost:8000
AEGIS_BASE_URL=http://localhost:8001
```

### Mock Responses

For testing without triggering real audits, you can use a mock run_id and call the Aegis API directly:

```bash
# Fetch a stored InsightBundle (replace with a real run_id from your dev database)
curl -H "X-API-Key: dev-key" http://localhost:8001/auditor/synthesis/run_abc123xyz
```

## Maintenance

This skill uses the `@aegis/openclaw-connector` package internally. If you're modifying the skill logic:

1. Clone the `analygo_aegis` repository
2. Update the connector code in `packages/openclaw-connector/src/`
3. Build the connector: `pnpm --filter @aegis/openclaw-connector build`
4. Update this SKILL.md file with any new endpoints or parameters
5. Test the skill in OpenClaw with a local audit run

## Support

For issues or questions:

- Check `docs/openclaw/README.md` for installation and setup instructions
- Review the `analygo_aegis` codebase at `/Users/pro/Documents/analygo_aegis`
- Contact the Analygo team for API access and configuration
