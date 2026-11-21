---
name: okf-open-knowledge-format
description: >
  Create, validate, and enrich Open Knowledge Format (OKF) bundles — the open
  spec for representing organizational knowledge as markdown files with YAML
  frontmatter. Use when the user mentions 'OKF', 'Open Knowledge Format',
  'knowledge bundle', 'OKF bundle', 'create a knowledge base for agents',
  'validate OKF', 'convert to OKF', 'enrich knowledge docs', 'agent-readable
  knowledge', 'LLM wiki', 'knowledge catalog', 'kcmd', or wants to structure
  knowledge as markdown files for AI agent consumption. Also use when the user
  has a directory of markdown files and wants to make them interoperable or
  conformant with the OKF standard. Even for simple requests like 'make this
  folder OKF conformant' — the skill has critical structural rules the agent
  needs.
metadata:
  author: ft.ia.br
  version: "2.0"
  date: 2026-08-25
  repository: https://github.com/fabricioctelles/skills
  license: Apache-2.0
  category: library-and-api-reference
  upstream: https://github.com/GoogleCloudPlatform/open-knowledge-format
---

# Open Knowledge Format (OKF)

OKF v0.2 is a vendor-neutral open spec for representing knowledge as markdown files with YAML frontmatter. No SDK required — if you can `cat` a file, you can read OKF.

- **Full spec:** [references/spec-v02.md](references/spec-v02.md)
- **Legacy spec (v0.1):** [references/spec-v01.md](references/spec-v01.md)
- **Examples:** [references/examples.md](references/examples.md)
- **Conversion guide:** [references/conversion.md](references/conversion.md)

### Design Principles

1. **Minimally opinionated** — Only `type` is required.
2. **Producer/consumer independence** — Human-authored bundles feed agents; LLM-generated bundles are browsed by humans.
3. **Format, not platform** — No cloud, SDK, or vendor dependency.
4. **Trust is first-class** — Provenance, verification, and freshness from frontmatter.

---

## Quick Reference — Core Frontmatter Fields

| Field | Required? | Description |
|-------|-----------|-------------|
| `type` | **YES** | Kind of concept (free-form string) |
| `title` | Recommended | Human-readable display name |
| `description` | Recommended | One-sentence summary |
| `resource` | Recommended | URI identifying the underlying asset |
| `tags` | Optional | YAML list for cross-cutting categorization |

v0.2 trust & lifecycle fields — see [spec-v02.md](references/spec-v02.md) for full docs:

| Field | Description |
|-------|-------------|
| `generated` | `{ by: <actor>, at: <ISO8601> }` — Who/what created this content |
| `verified` | List of `{ by: <actor>, at: <ISO8601> }` — Who confirmed correctness |
| `status` | `draft` \| `stable` \| `deprecated` |
| `stale_after` | ISO 8601 datetime — Content is stale after this instant |
| `sources` | List of source entries for provenance (see spec for full shape) |

### Reserved Filenames

| File | Purpose | Has frontmatter? |
|------|---------|-----------------|
| `index.md` | Directory listing for progressive disclosure | NO* |
| `log.md` | Change history, newest first | NO |

*Exception: bundle-root `index.md` MAY have frontmatter with `okf_version: "0.2"`.

---

## Create a Bundle

### 1. Determine scope and structure

Ask: What knowledge are we capturing? (tables, metrics, APIs, playbooks, etc.)
Organize into a directory tree.

### 2. Create concept documents

Each concept = one `.md` file. Minimal conformant example:

```markdown
---
type: Metric
---
# Monthly Recurring Revenue (MRR)
Sum of all active subscriptions normalized to a monthly amount.
```

v0.2 with provenance:

```markdown
---
type: Metric
title: Monthly Recurring Revenue
description: Sum of all active subscription revenue normalized to monthly.
tags: [revenue, saas, kpi]
status: stable
generated: { by: human:ftelles, at: 2026-08-25T10:00:00Z }
verified: { by: human:finance-lead, at: 2026-08-25T14:00:00Z }
stale_after: 2026-12-31T00:00:00Z
sources:
  - id: stripe-docs
    resource: https://stripe.com/docs/billing/subscriptions
    title: Stripe Subscription Billing
    author: team:stripe-docs
    last_modified: 2026-06-01T00:00:00Z
---
# Monthly Recurring Revenue (MRR)
Sum of all active subscriptions normalized to a monthly amount.[^stripe-docs]
Excludes one-time fees and overages.

## Formula
`MRR = Σ(active_subscription_monthly_value)`

[^stripe-docs]: Stripe Subscription Billing
```

For more examples across domains, see [references/examples.md](references/examples.md).

### 3. Cross-link concepts

- **Absolute** (preferred — stable when files move): `[customers](/tables/customers.md)`
- **Relative**: `[churn](./churn.md)`

Links assert relationships by prose context. Broken links are explicitly permitted.

### 4. Add provenance with footnotes (v0.2)

```yaml
sources:
  - id: ga4-schema
    resource: https://developers.google.com/analytics/bigquery/export-schema
    title: GA4 BigQuery Export schema
```

```markdown
The `events_` table is sharded daily as `events_YYYYMMDD`.[^ga4-schema]

[^ga4-schema]: GA4 BigQuery Export schema
```

### 5. Generate `index.md`

Place in any directory. No frontmatter. Format:

```markdown
# Metrics
- [MRR](./mrr.md) - Monthly recurring revenue
- [Churn](./churn.md) - Monthly churn rate
```

Include the description from each concept's frontmatter.

### 6. Generate `log.md` (optional)

Chronological change history, newest first:

```markdown
# Update Log
## 2026-08-25
- **Creation**: Added MRR, Churn, and NPS metrics.
```

### 7. Declare version (optional)

Bundle-root `index.md`:

```markdown
---
okf_version: "0.2"
---
# My Knowledge Bundle
- [Tables](./tables/)
- [Metrics](./metrics/)
```

### 8. Distribution

- **git repository** (recommended)
- Tarball or zip
- Subdirectory in a larger repo

### 9. Verify conformance

Three rules:
1. Every non-reserved `.md` file has parseable YAML frontmatter
2. Every frontmatter has a non-empty `type` field
3. Reserved files (`index.md`, `log.md`) follow defined structure when present

---

## Create an Attested Computation (v0.2)

For verifiable, reproducible calculations (finance KPIs, compliance metrics, any "did the sanctioned thing run" scenario).

### Structure

```markdown
---
type: Attested Computation
title: Revenue for fiscal year
description: Recognized revenue for a fiscal year, per Finance's definition.
runtime: bigquery
parameters:
  - { name: year, type: integer, required: true }
executor:
  resource: references/skills/run-on-bq.md
  receipt: [job_id, executed_sql, result]
attester:
  resource: references/attesters/revenue.py
generated: { by: reference_agent/gemini-2.5-pro, at: 2026-06-20T22:53:05Z }
verified: { by: human:ahormati, at: 2026-06-25T09:00:00Z }
---
# Computation
    SELECT SUM(amount) AS revenue
    FROM finance.recognized_revenue
    WHERE fiscal_year = @year
```

### Key rules

1. **Agent fills parameters only** — never edits the computation itself
2. **Computation can be inline** (`# Computation` heading) or external (`computation:` field)
3. **Executor produces receipt** — evidence the attester inspects
4. **Attester is deterministic** — no LLM, just code

---

## Validate a Bundle

### Preferred: okflint (when available)

[okflint](https://github.com/mattdav/okflint) — 18 rules across 3 tiers.

**Agent behavior:** Check if installed (`command -v okflint`). If NOT, ask user:

> "okflint não está instalado. Quer que eu instale?
> 1. `uv tool install okflint` (recomendado)
> 2. `pip install okflint`
> 3. Seguir sem ele (validação básica com script embutido)"

If user agrees:

```bash
uv tool install okflint
okflint --version
```

Full validation:

```bash
if [ -f okf-base.yaml ]; then
  okflint validate --manifest okf-base.yaml ./bundle/
else
  okflint validate ./bundle/
fi
```

### Fallback: built-in bash script

```bash
bash scripts/validate.sh [bundle-dir]
```

Checks the 3 core conformance rules + v0.2 fields. See [scripts/validate.sh](scripts/validate.sh).

### Validation report format

```
✅ PASS: 12/12 concept files have valid frontmatter with type field
✅ PASS: index.md follows list structure (no frontmatter)
✅ PASS: log.md uses ISO 8601 date headings, newest first
⚠  WARNING: 3 files missing 'description' field
⚠  WARNING: 2 broken cross-links
ℹ  INFO: 5 files with trust fields
ℹ  INFO: 2 Attested Computation concepts found
```

### Error codes

- `E1`: No YAML frontmatter
- `E2`: Frontmatter missing `type`
- `E3`: Reserved file has unexpected structure
- `E4`: Attested Computation missing `runtime`

### Warnings (non-blocking)

- `W1`: Missing `title` or `description`
- `W2`: Broken cross-link
- `W3`: No `generated` field
- `W4`: No `index.md` in directory
- `W5`: `log.md` dates not ISO 8601
- `W6`: `sources` entry missing `resource`
- `W7`: `stale_after` date has passed

Consumers MUST NOT reject for: missing optional fields, unknown types/keys, broken links, missing index files.

---

## Enrich Concepts

### Add schema section

```markdown
# Schema
| Column | Type | Description |
|--------|------|-------------|
| `order_id` | STRING | Unique identifier |
| `customer_id` | STRING | FK to [customers](/tables/customers.md) |
```

### Add examples section

Fenced code blocks showing usage.

### Add provenance (v0.2)

```yaml
sources:
  - id: official-docs
    resource: https://example.com/docs
    title: Official Documentation
```

### Add trust signals (v0.2)

```yaml
generated: { by: reference_agent/gemini-2.5-pro, at: 2026-08-25T10:00:00Z }
verified: { by: human:domain-expert, at: 2026-08-25T14:00:00Z }
status: stable
stale_after: 2026-12-31T00:00:00Z
```

### Add cross-links

Weave into natural prose — don't create standalone "links" sections.

### Fill recommended fields

If `title`, `description`, `tags` missing, add them.

---

## Migrate v0.1 to v0.2

### Breaking changes

1. **`timestamp` → `generated.at`**
   ```yaml
   # v0.1
   timestamp: 2026-05-28T22:53:05Z
   # v0.2
   generated: { by: human:author, at: 2026-05-28T22:53:05Z }
   ```

2. **`# Citations` → `sources`**
   ```yaml
   # v0.2 frontmatter
   sources:
     - id: docs
       resource: https://example.com/docs
       title: Example Documentation
   ```

### Backward compatibility

v0.2 consumers SHOULD fall back to `timestamp` when `generated` absent, and parse legacy `# Citations` when `sources` absent.

---

## Convert Sources to OKF

See [references/conversion.md](references/conversion.md) for detailed guides.

**Quick rules:**

| Source | Conversion |
|--------|-----------|
| **Notion export** | Properties → frontmatter. Remove UUID suffixes. Notion links → relative markdown. |
| **Obsidian vault** | `[[wikilinks]]` → `[title](./file.md)`. Ensure `type`. Move `#tags` to frontmatter. |
| **CSV/spreadsheet** | Each row = one concept. Map columns to frontmatter. First column = filename. |

---

## Actor Convention

Fields recording identity use:

- `<producer>/<version>` for agents: `reference_agent/gemini-2.5-pro`
- `human:<id>` for people: `human:ahormati`
- `process:<id>` for automation: `process:finance-nightly`

### Trust Tiers

| Condition | Tier |
|-----------|------|
| No `verified` key | **Unverified** |
| `verified` by non-`human:` actors only | **Machine-confirmed** |
| `verified` by a `human:<id>` actor | **Human-reviewed** |

---

## Guardrails

1. **NEVER invent data.** No fabricated URLs or column names.
2. **Preserve unknown fields.** OKF allows extension. Don't delete unrecognized keys.
3. **Don't impose taxonomy.** Type values are free-form. Suggest, never reject.
4. **Broken links are OK.** They represent not-yet-written knowledge.
5. **Minimal by default.** Generate only `type` + warranted fields. No padding.
6. **Ask before assuming.** If domain is unclear, ask.
7. **Respect trust hierarchy.** Only mark `verified` by `human:` if actually human-reviewed.
8. **Computation integrity.** Never edit the computation in Attested Computation — only fill parameters.

---

## Output Format

When creating a bundle, present:

1. **Directory tree** of the full structure
2. **Each file's content** in fenced code blocks
3. **Conformance check** — passes the 3 rules
4. **Trust summary**

```
saas-metrics/
├── index.md
├── log.md
├── metrics/
│   ├── index.md
│   ├── mrr.md
│   ├── churn.md
│   └── nps.md
└── computations/
    └── mrr-calculation.md
```

```
Bundle is OKF v0.2 conformant ✅
- 4 concept files
- 1 Attested Computation
- 3 human-verified, 1 unverified
- 0 stale concepts
```

---

## Google Cloud Integration (Optional)

See [spec-v02.md](references/spec-v02.md) for enterprise integration with Google Cloud Knowledge Catalog and kcmd CLI. This is the enterprise path — skip unless the user needs it.