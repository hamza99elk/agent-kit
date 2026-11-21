# OpenClaw Setup Guide for Analygo Audit

This guide walks you through installing OpenClaw and configuring the `analygo-audit` skill for triggering and monitoring consent compliance audits.

## What is OpenClaw?

OpenClaw is a personal AI assistant that runs locally on your machine and integrates with messaging platforms (WhatsApp, Telegram, Slack). It loads skill files that define API interactions, enabling you to trigger complex workflows via natural language chat.

The `analygo-audit` skill enables you to:

- Trigger consent audits for any website via chat (e.g., "Audit shopify.com")
- Monitor audit progress and retrieve InsightBundles with compliance findings
- Query past audit results (e.g., "What did the last audit find for maxibeauty.ma?")

## Prerequisites

- **Operating System:** macOS or Linux (Windows: use PowerShell installer from [openclaw.ai](https://openclaw.ai))
- **Node.js:** v22+ (auto-installed by the installer if missing)
- **pnpm:** Latest version (auto-installed by the installer if missing)
- **API Access:** You need API keys for the Analygo platform and Aegis (contact the Analygo team for access)

## Installation

### Step 1: Install OpenClaw

Run the OpenClaw installer script:

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

The installer will:

1. Check for Node.js v22+ and install it if missing
2. Check for pnpm and install it if missing
3. Download and install the latest OpenClaw binary
4. Add OpenClaw to your PATH (you may need to restart your shell)

Verify the installation:

```bash
openclaw --version
```

Expected output: `openclaw v1.x.x` (or similar)

### Step 2: First-Run Setup

Launch the OpenClaw onboarding wizard:

```bash
openclaw onboard
```

The wizard will guide you through:

1. **Model Provider Selection:**
   - Choose your preferred LLM provider:
     - **Kimi** (recommended for speed and cost)
     - **Claude** (Anthropic API)
     - **Ollama** (local models, requires separate installation)
   - Enter your API key for the selected provider

2. **Messaging Integration:**
   - Choose your primary messaging platform:
     - **WhatsApp** (requires QR code scan)
     - **Telegram** (requires bot token)
     - **Slack** (requires OAuth app setup)
   - Follow the platform-specific setup instructions

3. **Workspace Creation:**
   - OpenClaw creates a workspace directory at `~/.openclaw/workspace/`
   - Skills are loaded from subdirectories in this workspace

The onboarding wizard creates a config file at `~/.openclaw/openclaw.json` with your settings.

### Step 3: Configure API Keys

OpenClaw is now installed, but you need to configure the Analygo API keys for the audit skill to work.

Edit the OpenClaw config file:

```bash
nano ~/.openclaw/openclaw.json
# or use your preferred editor: vim, vscode, etc.
```

Add the following environment variables to the config:

```json
{
  "model": {
    "provider": "kimi",
    "apiKey": "your-kimi-api-key"
  },
  "messaging": {
    "platform": "whatsapp",
    "config": { ... }
  },
  "env": {
    "PLATFORM_API_KEY": "your-platform-api-key",
    "PLATFORM_BASE_URL": "https://platform.analygo.ai",
    "AEGIS_BASE_URL": "http://localhost:8001",
    "AEGIS_API_KEY": "your-aegis-api-key"
  }
}
```

**Configuration notes:**

- `PLATFORM_API_KEY`: Your Analygo platform API key (contact the Analygo team to obtain this)
- `PLATFORM_BASE_URL`: Production URL (`https://platform.analygo.ai`) or local dev URL (`http://localhost:8000`)
- `AEGIS_BASE_URL`: Aegis API URL (local: `http://localhost:8001`, production: TBD)
- `AEGIS_API_KEY`: Optional, only required if Aegis has authentication enabled

For local development, use:

```json
{
  "env": {
    "PLATFORM_API_KEY": "dev-key",
    "PLATFORM_BASE_URL": "http://localhost:8000",
    "AEGIS_BASE_URL": "http://localhost:8001",
    "AEGIS_API_KEY": "dev-key"
  }
}
```

### Step 4: Install the Analygo Audit Skill

Create the skill directory in the OpenClaw workspace:

```bash
mkdir -p ~/.openclaw/workspace/analygo-audit
```

Copy the skill file from the `analygo_aegis` repository to the workspace:

```bash
cp /Users/pro/Documents/analygo_aegis/docs/openclaw/SKILL.md ~/.openclaw/workspace/analygo-audit/SKILL.md
```

**For team members without local repo access:**

Download the skill file directly:

```bash
curl -fsSL https://raw.githubusercontent.com/analygo/aegis/main/docs/openclaw/SKILL.md \
  -o ~/.openclaw/workspace/analygo-audit/SKILL.md
```

(Replace the GitHub URL with the actual repository URL once the file is committed)

Verify the skill is loaded:

```bash
openclaw skills list
```

Expected output should include:

```
analygo-audit — Trigger and monitor consent compliance audits via analygo platform and Aegis.
```

### Step 5: Start OpenClaw

Launch OpenClaw in the background:

```bash
openclaw start
```

OpenClaw will:

1. Load all skills from `~/.openclaw/workspace/`
2. Connect to your configured messaging platform (WhatsApp, Telegram, or Slack)
3. Listen for messages and execute skills based on user input

To check the status:

```bash
openclaw status
```

To view logs:

```bash
openclaw logs
```

To stop OpenClaw:

```bash
openclaw stop
```

## End-to-End Usage Walkthrough

### Example 1: Trigger an Audit

**Chat with OpenClaw (via WhatsApp, Telegram, or Slack):**

```
You: Audit shopify.com
```

**OpenClaw response:**

```
✅ Audit queued for shopify.com (run ID: run_abc123xyz)
⏳ Polling status... this may take 2-5 minutes.
```

(After ~3 minutes)

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

### Example 2: Query a Previous Audit

**Chat:**

```
You: What did the last audit find for maxibeauty.ma?
```

**OpenClaw response:**

```
📋 Last audit for maxibeauty.ma (run: run_xyz789abc)

Severity: MEDIUM
Business Impact: Potential GDPR violation — risk of user complaints and regulatory scrutiny

Narrative:
The audit identified 1 consent violation. A third-party script (Hotjar) was loaded before consent acceptance, capturing user interactions without authorization.

Recommended Action:
Implement consent gating for Hotjar script; review all third-party scripts for consent compliance.

Violations:
- Premature script load: Hotjar loaded before consent acceptance
```

### Example 3: Trigger Audit Without Puppet Interaction

**Chat:**

```
You: Audit example.com but skip the puppet interaction
```

**OpenClaw response:**

```
✅ Audit queued for example.com (run ID: run_def456ghi) — skipping puppet interaction
⏳ Polling status...
```

(Audit completes faster since no browser interaction is performed)

```
✅ Audit completed for example.com (run: run_def456ghi)

Severity: LOW
Business Impact: Minor compliance gap — no immediate regulatory risk

Narrative:
The audit detected 0 consent violations. All tracking tags are properly gated behind consent acceptance.

Recommended Action:
No immediate action required. Continue monitoring for changes.
```

## Troubleshooting

### OpenClaw doesn't respond to messages

1. Check that OpenClaw is running: `openclaw status`
2. Check logs for errors: `openclaw logs`
3. Verify messaging integration config in `~/.openclaw/openclaw.json`
4. Restart OpenClaw: `openclaw stop && openclaw start`

### "Invalid or missing API key" error

1. Verify `PLATFORM_API_KEY` and `AEGIS_API_KEY` are set in `~/.openclaw/openclaw.json`
2. Check that the API keys are valid (contact the Analygo team if unsure)
3. For local development, ensure the backend is running: `cd backend && uvicorn app.main:app --port 8001 --reload`

### "No insight found for run_id" error

This error occurs when:

- The audit is still running (status is `queued` or `running`) — wait for the audit to complete
- The audit failed before synthesis — check the platform run status for error details
- The run_id is invalid — verify the run_id with `openclaw logs`

### Audit times out after 10 minutes

Long-running audits may timeout due to:

- Complex website with many pages or scripts
- Slow network connection
- Platform infrastructure issues

To retry:

```
You: Audit example.com
```

If the issue persists, contact the Analygo team for support.

### Skill not loaded

If `openclaw skills list` doesn't show `analygo-audit`:

1. Verify the skill file exists: `ls ~/.openclaw/workspace/analygo-audit/SKILL.md`
2. Check the YAML frontmatter is valid (must have `name`, `description`, and `user-invocable: true`)
3. Restart OpenClaw: `openclaw stop && openclaw start`

## Advanced Configuration

### Using a Custom Model

To use a different LLM provider or model, edit `~/.openclaw/openclaw.json`:

```json
{
  "model": {
    "provider": "ollama",
    "model": "llama3.1:70b",
    "baseUrl": "http://localhost:11434"
  }
}
```

Supported providers: `kimi`, `claude`, `openai`, `ollama`

### Running Multiple Skills

OpenClaw can load multiple skills simultaneously. To add another skill:

1. Create a new subdirectory in `~/.openclaw/workspace/` (e.g., `~/.openclaw/workspace/my-skill/`)
2. Add a `SKILL.md` file with the skill definition
3. Restart OpenClaw: `openclaw stop && openclaw start`

### Viewing Audit History

OpenClaw maintains a local cache of recent audits. To view the cache:

```bash
cat ~/.openclaw/cache/analygo-audit.json
```

The cache stores run_ids and site_urls for quick re-lookup. Cache expiration: 7 days.

## Support and Feedback

For issues, questions, or feature requests:

- **OpenClaw:** Visit [openclaw.ai](https://openclaw.ai) or email support@openclaw.ai
- **Analygo Audit:** Contact the Analygo team or open an issue in the `analygo_aegis` repository
- **Skill Updates:** Pull the latest changes from the `analygo_aegis` repository and re-copy `SKILL.md` to `~/.openclaw/workspace/analygo-audit/`

## Next Steps

- Review the skill file: `cat ~/.openclaw/workspace/analygo-audit/SKILL.md`
- Test the skill with a local audit: "Audit localhost:3000"
- Explore OpenClaw's other built-in skills: `openclaw skills list`
- Customize the skill for your team's workflow (e.g., add Slack notifications, integrate with Notion)

Happy auditing! 🎉
