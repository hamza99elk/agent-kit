# Evaluating skills — full iteration loop

Load this reference when running test cases, grading, aggregating benchmarks, and iterating on a skill. Designed for the skill-creator workflow: draft → test → review → improve → repeat.

## Test cases — evals/evals.json

Start with 2-3 prompts. Vary phrasing, detail, edge cases. Include realistic context (file paths, column names, company names, casual speech).

```json
{
  "skill_name": "<name>",
  "evals": [
    {
      "id": 1,
      "prompt": "Realistic user message with file paths and context",
      "expected_output": "What success looks like",
      "files": ["evals/files/input.csv"],
      "assertions": ["Verifiable check"]
    }
  ]
}
```

## Workflow per iteration

### 1. Spawn all runs in the same turn

For each test case, launch two subagents at once — one with the skill, one without (baseline). Do NOT run with-skill first then baselines later.

**With-skill:** Provide skill path, prompt, input files. Save to `<workspace>/iteration-N/eval-<name>/with_skill/outputs/`.

**Baseline:** No skill path (new skill) or old snapshot. Save to `without_skill/outputs/` or `old_skill/outputs/`.

Create `eval_metadata.json` per case with prompts (assertions empty for now).

### 2. Draft assertions while runs are in progress

Don't wait idly — use this time to write quantitative assertions. Good ones are objectively verifiable and read clearly in the benchmark viewer. Subjective skills (writing, design) are better evaluated qualitatively — don't force assertions.

Update `eval_metadata.json` and `evals/evals.json` with assertions once drafted.

### 3. Capture timing on completion

Save `total_tokens`, `duration_ms` from each task notification immediately to `timing.json`. This fires exactly once per subagent — save it then.

### 4. Grade & aggregate

Grade each run against assertions. Save to `grading.json`:

```json
{
  "assertion_results": [
    { "text": "<assertion>", "passed": true, "evidence": "<quote or reference>" }
  ],
  "summary": { "passed": 2, "failed": 1, "total": 3, "pass_rate": 0.66 }
}
```

Aggregate into `benchmark.json`: pass rates, time, tokens per configuration, with delta.

### 5. Launch eval viewer — BEFORE evaluating yourself

Always run the viewer to get outputs in front of the human first:

```bash
python -m eval-viewer.generate_review.py <workspace>/iteration-N --skill-name "<name>" --benchmark <workspace>/iteration-N/benchmark.json
```

For headless: `--static <output_path>`.

For iteration 2+: also `--previous-workspace <workspace>/iteration-<N-1>`.

### 6. Read feedback & iterate

Read `feedback.json` from the viewer. Empty feedback = user was fine. Focus improvements on cases with specific complaints.

**Improvement principles:**
- **Generalize** — don't overfit to specific test prompts. Fix underlying issues broadly.
- **Keep lean** — remove instructions that aren't pulling their weight. Read transcripts, not just outputs.
- **Explain the why** — theory of mind over MUST/ALWAYS caps. Models follow better when they understand.
- **Bundle repeated work** — if all test cases wrote similar helper scripts, ship one in `scripts/`.

Then: improve → new iteration → rerun → repeat. Stop when feedback is consistently empty or improves uneventfully.

## What not to do

- Don't skip baseline runs for new skills
- Don't spawn test cases serially (parallel is the point)
- Don't write assertions that are brittle or trivial
- Don't overfit to test prompts — the skill will be used millions of times across different inputs

---

*Full guide: https://agentskills.io/skill-creation/evaluating-skills.md*