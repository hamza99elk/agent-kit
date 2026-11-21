---
name: sk-fullstack-practices
description: >
  Apply the user's full-stack development conventions when building, scaffolding, or reviewing backend and full-stack projects. Use when the user asks to build a new app, set up a backend service, implement auth, error handling, database access, API clients, logging, caching, file uploads, real-time features, background jobs, production hardening, write integration code across the frontend-backend boundary, or review backend architecture. Also use when the user's request involves API design, service layers, middleware, or project structure decisions — even if they don't explicitly name these patterns. NOT for pure frontend UI concerns, pure database schema design without backend context, or one-off scripts.
license: MIT
metadata:
  author: user
  version: 1.0.0
---

# Full-Stack Practices — Project Conventions & Patterns

Best practices: https://agentskills.io/skill-creation/best-practices.md

---

## MANDATORY WORKFLOW — Follow These Steps In Order

**When this skill is triggered, you MUST follow this workflow before writing any code.**

### Step 0: Gather Requirements

Before scaffolding anything, ask the user to clarify (or infer from context):

1. **Stack**: Language/framework for backend and frontend (e.g., Express + React, Django + Vue, Go + HTMX)
2. **Service type**: API-only, full-stack monolith, or microservice?
3. **Database**: SQL (PostgreSQL, SQLite, MySQL) or NoSQL (MongoDB, Redis)?
4. **Integration**: REST, GraphQL, tRPC, or gRPC?
5. **Real-time**: Needed? If yes — SSE, WebSocket, or polling?
6. **Auth**: Needed? If yes — JWT, session, OAuth, or third-party (Clerk, Auth.js)?

If the user has already specified these in their request, skip asking and proceed.

### Step 1: Architectural Decisions

Based on requirements, make and state these decisions before coding:

| Decision | Options | Reference |
|----------|---------|-----------|
| Project structure | Feature-first (recommended) vs layer-first | [references/project-structure.md](references/project-structure.md) |
| API client approach | Typed fetch / React Query / tRPC / OpenAPI codegen | [references/api-clients.md](references/api-clients.md) |
| Auth strategy | JWT + refresh / session / third-party | [references/auth.md](references/auth.md) |
| Real-time method | Polling / SSE / WebSocket | [references/real-time.md](references/real-time.md) |
| Error handling | Typed error hierarchy + global handler | [references/error-handling.md](references/error-handling.md) |

Briefly explain each choice (1 sentence per decision).

### Step 2: Scaffold with Checklist

Use the appropriate checklist below. Ensure ALL checked items are implemented — do not skip any.

### Step 3: Implement Following Patterns

Write code following the patterns in this document. Reference specific reference files as you implement each part.

### Step 4: Test & Verify

After implementation, run these checks before claiming completion:

1. **Build check**: Ensure both backend and frontend compile without errors
   ```bash
   # Backend
   cd server && npm run build
   # Frontend
   cd client && npm run build
   ```
2. **Start & smoke test**: Start the server, verify key endpoints return expected responses
   ```bash
   # Start server, then test
   curl http://localhost:3000/health
   curl http://localhost:3000/api/<resource>
   ```
3. **Integration check**: Verify frontend can connect to backend (CORS, API base URL, auth flow)
4. **Real-time check** (if applicable): Open two browser tabs, verify changes sync

If any check fails, fix the issue before proceeding.

### Step 5: Handoff Summary

Provide a brief summary to the user:

- **What was built**: List of implemented features and endpoints
- **How to run**: Exact commands to start backend and frontend
- **What's missing / next steps**: Any deferred items, known limitations, or recommended improvements
- **Key files**: List the most important files the user should know about

---

## Quick Start — New Backend Service Checklist

- [ ] Project scaffolded with **feature-first** structure
- [ ] Configuration **centralized**, env vars **validated at startup** (fail fast)
- [ ] **Typed error hierarchy** defined (not generic `Error`)
- [ ] **Global error handler** middleware
- [ ] **Structured JSON logging** with request ID propagation
- [ ] Database: **migrations** set up, **connection pooling** configured
- [ ] **Input validation** on all endpoints (Zod / Pydantic / Go validator)
- [ ] **Authentication middleware** in place
- [ ] **Health check** endpoints (`/health`, `/ready`)
- [ ] **Graceful shutdown** handling (SIGTERM)
- [ ] **CORS** configured (explicit origins, not `*`)
- [ ] **Security headers** (helmet or equivalent)
- [ ] `.env.example` committed (no real secrets)

## Quick Start — Frontend-Backend Integration Checklist

- [ ] **API client** configured (typed fetch wrapper, React Query, tRPC, or OpenAPI generated)
- [ ] **Base URL** from environment variable (not hardcoded)
- [ ] **Auth token** attached to requests automatically (interceptor / middleware)
- [ ] **Error handling** — API errors mapped to user-facing messages
- [ ] **Loading states** handled (skeleton/spinner, not blank screen)
- [ ] **Type safety** across the boundary (shared types, OpenAPI, or tRPC)
- [ ] **CORS** configured with explicit origins (not `*` in production)
- [ ] **Refresh token** flow implemented (httpOnly cookie + transparent retry on 401)

---

## Quick Navigation

| Need to… | Reference |
|----------|-----------|
| Organize project folders, layer architecture, DI | [references/project-structure.md](references/project-structure.md) |
| Set up typed error hierarchy + global handler | [references/error-handling.md](references/error-handling.md) |
| Manage config + env vars | [references/project-structure.md](references/project-structure.md) §Configuration |
| Write database code (migrations, N+1, transactions, pooling) | [references/database.md](references/database.md) |
| Set up API client from frontend | [references/api-clients.md](references/api-clients.md) |
| Add auth middleware, JWT, RBAC, token refresh | [references/auth.md](references/auth.md) |
| Set up structured JSON logging | [references/logging.md](references/logging.md) |
| Add background jobs + caching | [references/jobs-caching.md](references/jobs-caching.md) |
| Implement file uploads (presigned URL, multipart) | [references/file-upload.md](references/file-upload.md) |
| Add real-time features (SSE, WebSocket, polling) | [references/real-time.md](references/real-time.md) |
| Cross-boundary error handling (API errors → UI) | [references/error-handling.md](references/error-handling.md) §Cross-boundary |
| Harden for production | [references/production.md](references/production.md) |

---

## Core Principles (7 Iron Rules)

```
1. ✅ Organize by FEATURE, not by technical layer
2. ✅ Controllers never contain business logic
3. ✅ Services never import HTTP request/response types
4. ✅ All config from env vars, validated at startup, fail fast
5. ✅ Every error is typed, logged, and returns consistent format
6. ✅ All input validated at the boundary — trust nothing from client
7. ✅ Structured JSON logging with request ID — not console.log
```

These are non-negotiable. Violating any of these in generated code is a bug. If a framework or library pushes you toward violating one, find a workaround.

---

## Anti-Patterns

| # | ❌ Don't | ✅ Do Instead |
|---|---------|--------------|
| 1 | Business logic in routes/controllers | Move to service layer |
| 2 | `process.env` scattered everywhere | Centralized typed config |
| 3 | `console.log` for logging | Structured JSON logger |
| 4 | Generic `Error('oops')` | Typed error hierarchy |
| 5 | Direct DB calls in controllers | Repository pattern |
| 6 | No input validation | Validate at boundary (Zod/Pydantic) |
| 7 | Catching errors silently | Log + rethrow or return error |
| 8 | No health check endpoints | `/health` + `/ready` |
| 9 | Hardcoded config/secrets | Environment variables |
| 10 | No graceful shutdown | Handle SIGTERM properly |
| 11 | Hardcode API URL in frontend | Environment variable (`NEXT_PUBLIC_API_URL`) |
| 12 | Store JWT in localStorage | Memory + httpOnly refresh cookie |
| 13 | Show raw API errors to users | Map to human-readable messages |
| 14 | Retry 4xx errors | Only retry 5xx (server failures) |
| 15 | Skip loading states | Skeleton/spinner while fetching |
| 16 | Upload large files through API server | Presigned URL → direct to S3 |
| 17 | Poll for real-time data | SSE or WebSocket |
| 18 | Duplicate types frontend + backend | Shared types, tRPC, or OpenAPI codegen |

---

## Gotchas

- **Layers are not optional.** A controller that directly queries the database or a service that returns HTTP responses is a bug. The three layers (Controller → Service → Repository) must be separate, even in small projects.
- **Framework pushback.** Express/FastAPI make it tempting to put logic in route handlers because it's faster. Resist this — the pattern pays off on the first refactor or test.
- **Config propagation.** When adding a new env var, add the typed accessor in the config module and set a sensible default. Never reach for `process.env.FOO` at the call site — if the key changes, you have to find every usage.
- **Error type confusion.** `NotFoundError` is not a "user input error" — use `ValidationError` for bad input (422) and `NotFoundError` for missing resources (404). The status code is part of the error class contract.
- **Frontend-backend type drift.** If using manual types (not tRPC or OpenAPI codegen), the shared type files must be the single source of truth. When the API changes, update the shared types first — not the frontend DTOs independently.
- **Retry logic scope.** Only retry on 5xx. A 401 means "the credentials are wrong or expired" — retrying will compound the failure. Handle 401 by attempting a refresh token exchange once, then redirect to login if it fails.
- **SSE vs WebSocket.** SSE is often the better default for most apps because it's simpler, auto-reconnects, works through HTTP proxies, and the server push direction covers the majority of real-time use cases (notifications, feeds, status updates). Don't jump to WebSocket unless you need bidirectional communication (chat, collaborative editing).

---

## Integration Decision Tree

```
Same team owns frontend + backend?
│
├─ YES, both TypeScript
│   └─ tRPC (end-to-end type safety, zero codegen)
│
├─ YES, different languages
│   └─ OpenAPI spec → generated client (type safety via codegen)
│
├─ NO, public API
│   └─ REST + OpenAPI → generated SDKs for consumers
│
└─ Complex data needs, multiple frontends
    └─ GraphQL + codegen (flexible queries per client)

Real-time needed?
│
├─ Server → Client only (notifications, feeds, AI streaming)
│   └─ SSE (simplest, auto-reconnect, works through proxies)
│
├─ Bidirectional (chat, collaboration)
│   └─ WebSocket (need heartbeat + reconnection logic)
│
└─ Simple status polling (< 10 clients)
    └─ React Query refetchInterval (no infrastructure needed)
```

---

*Generated by sk-build-skill*
