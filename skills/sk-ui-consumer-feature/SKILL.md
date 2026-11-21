---
name: sk-ui-consumer-feature
description: >-
  Build or refactor domain-specific UI sections and feature components in
  Analygo consumer apps. Use when turning product requirements, API states,
  contracts, and user actions into reusable feature-local sections (such as
  decision queues, ecosystem overviews, contract reviews, or telemetry summaries)
  using existing @analygo/ui compositions, layouts, blocks, and Storybook contracts.
  Also use alongside sk-ui-consumer-guide when building substantial pages.
  Not for authoring shared packages/ui primitives or generic compositions.
license: MIT
metadata:
  version: "1.0"
---

# Analygo — Consumer Feature UI Authoring

## Purpose and boundaries

A **feature component** translates domain data, state, and actions into an
interface built from the shared UI system. A **page** arranges feature sections
and coordinates route-level data. `@analygo/ui` owns visual grammar, responsive
structure, semantics, and reusable interaction patterns.

Examples: `DecisionQueue`, `DecisionGate`, `EcosystemOverview`, `ContractReview`,
`TelemetrySummary`. These are **illustrative feature names**, not guaranteed
existing modules or exports.

**Always apply `sk-ui-consumer-guide` first** for component discovery, tokens,
imports, layout and lint rules. Do not use this skill as permission to hand-roll
something available in Storybook.

For page-level assembly and the page.tsx → *View.tsx pattern, see **`sk-ui-consumer-page-layout`**.
For reusable page layouts (Explorer, Detail, Canvas), see **`sk-ui-archetypes`**.

---

## 1. Workflow: spec → catalog → feature model → implementation

1. **Define user intent:** What decision, inspection, or action does this section
   enable? Identify the data source, actor, permissions, and result of actions.
2. **Audit UI inventory:** Inspect actual `@analygo/ui` public exports and
   Storybook stories. Prefer compatible shared sections/blocks and compositions.
3. **Define feature contract:** Model the feature's data, loading lifecycle,
   permissions, errors, actions, and invalid combinations before JSX.
4. **Partition responsibility:** Put data access/state orchestration in a
   feature controller/container, domain presentation in a feature section, and
   generic presentation in `@analygo/ui`.
5. **Implement with slots:** Fill documented slots of higher-level components;
   use `Stack`/`Grid`/`Card` only if the selected components leave a genuine gap.
6. **Verify:** Run relevant types, lint, unit/interaction/accessibility tests;
   inspect populated, empty, error, loading and constrained-width UI.
7. **Report gaps:** Flag a genuinely missing generic composition for review;
   do not add it to `packages/ui` as part of a consumer task without authorization.

## 2. Boundary ownership

| Responsibility | Owner |
|---|---|
| Tokens, spacing, typography, generic status visuals | `@analygo/ui` |
| Generic section/panel/row placement and responsive rules | `@analygo/ui` |
| GTM/contract/evidence/telemetry semantics | Consumer feature |
| API schemas and shared business invariants | `@analygo/contracts` (per existing repo conventions) |
| Fetching, mutations, permissions, data adapters | Consumer feature/application |
| Route composition, navigation and page-level coordination | Consumer page |

Never import consumer feature types into `packages/ui`. Never duplicate a
shared component just because a domain-specific label or icon is needed.

## 3. Domain contracts: data vs presentation

- Use existing schemas from `@analygo/contracts` where available. Respect the
  consumer rule against inline `z.object()` in component files.
- Validate untrusted API/configuration data at its boundary (or in the existing
  contract/data layer), not on every render.
- Use TypeScript for component slots, callbacks, refs, and trusted React props.
- Model mutually exclusive states with discriminated unions rather than a
  matrix of flags such as `isLoading`, `hasError`, `isEmpty`, `isHealthy`.
- Keep domain-specific variants and descriptions outside generic UI primitives.
- Define no-data, stale-data, unauthorized, failed, and partial-data behavior
  when those states are possible.

Illustrative TypeScript-only presentation contract:

```tsx
type DecisionQueueState =
  | { kind: "loading" }
  | { kind: "error"; message: string; onRetry: () => void }
  | { kind: "ready"; items: DecisionItem[] };

type DecisionQueueProps = {
  state: DecisionQueueState;
  onReview: (decisionId: string) => void;
};
```

`DecisionItem` must be imported from the real domain package or defined locally
if genuinely feature-private; do not invent a new shared schema for convenience.

## 4. Component API policy

Prefer **few domain-semantic props** with existing shared compositions handling
presentation. Use slots for variable regions instead of replicating underlying
component props (`titleColor`, `showDivider`, `headerGap`, `badgePosition`).

Good API:

```tsx
<DecisionQueue
  state={queueState}
  onReview={handleReview}
/>
```

Inside `DecisionQueue`, prefer the **actual verified** shared section/list/row
components. The following expresses intent, not a claim of existing exports:

```tsx
<SharedSection heading="Needs my decision" actions={<QueueActions />}>
  <SharedActionList>
    {items.map(item => (
      <SharedActionRow key={item.id} actions={<ReviewAction item={item} />}>
        <DecisionSummary item={item} />
      </SharedActionRow>
    ))}
  </SharedActionList>
</SharedSection>
```

Replace `SharedSection`, `SharedActionList`, and `SharedActionRow` with **verified
actual** `@analygo/ui` exports and their documented slot names. If a suitable
component is absent, compose approved primitives feature-locally and record it.

## 5. Component granularity and placement

- **Feature section:** one coherent user goal or task (`EcosystemOverview`).
- **Feature item:** repeatable domain presentation (`EcosystemResourceItem`).
- **Feature controller:** fetching, transforms, permissions and mutations.
- **Screen:** arranges feature sections using approved page layouts.

Suggested structure (adapt to existing repo conventions):

```text
apps/platform/features/decisions/
  components/
    decision-queue.tsx
    decision-summary.tsx
  decision-queue.types.ts
  decision-queue.test.tsx
  decision-queue.stories.tsx    # if local Storybook is configured
  hooks/                       # only if needed
```

Keep local components local until there is evidence of cross-feature generic
reuse; a frequently reused **domain** component need not become shared UI.

## 6. State and action correctness

- Do not show success before a mutation succeeds.
- Disable or hide unauthorized actions according to product requirements, and
  enforce authorization on the server as well.
- Distinguish `pending`, `failed`, `stale`, `unknown`, and `succeeded` when relevant.
- Provide retry/recovery paths for errors; avoid silently showing empty content.
- Preserve accessible names, focus flow, and keyboard interaction when composing.
- Do not create a custom status pill, table, header, spinner, or card when a
  suitable documented shared pattern exists.

## 7. Feature-level Storybook and tests

Build focused feature stories/tests where the repository supports them:

- Populated with realistic data shape (not production secrets)
- Empty and loading
- Error and retry
- Permission-limited state
- Long labels, missing optional fields, narrow viewport
- Interaction: user triggers review/action, pending and outcome states

A feature story demonstrates **domain states**; shared component stories remain
the source of truth for generic visual behavior. Never duplicate shared
component Storybook implementation to make the feature story work.

## 8. Completion checklist / agent handoff

- [ ] Identified goal, data source, actions, permissions and state lifecycle.
- [ ] Inspected shared exports and Storybook; chose highest compatible components.
- [ ] Defined domain state as a coherent typed contract; reused existing schemas.
- [ ] Kept network/data orchestration separate from reusable presentation.
- [ ] Avoided prop drilling of generic styling knobs and duplicate visual patterns.
- [ ] Verified responsive, accessible and all meaningful UI states.
- [ ] Ran available typecheck, lint, Storybook and feature tests.
- [ ] Reported any missing shared UI composition and why feature-local fallback was used.

**Handoff:** State which shared compositions were reused, which feature-local
components were created, relevant contract/state decisions, and any proposed
promotion candidate. Do not describe unexecuted tests as passed.

## Related Resources

- `sk-ui-consumer-guide` — Component discovery, tokens, imports, guardrails (apply first)
- `sk-ui-consumer-page-layout` — page.tsx → *View.tsx → components/ pattern, routing layout hierarchy
- `sk-ui-layout` — Layout primitives (Container, Stack, Grid, Surface)
- `sk-ui-archetypes` — Reusable page layouts (Explorer, Detail, Canvas)
- `packages/ui/src/foundation/*.mdx` — Token-level contracts
- `@analygo/contracts` — Shared domain schemas