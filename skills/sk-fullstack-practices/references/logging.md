# Logging & Observability

Load this reference when implementing structured logging, request ID propagation, or log level strategy.

---

## Structured JSON Logging

```typescript
// ✅ Structured — parseable, filterable, alertable
logger.info('Order created', {
  orderId: order.id, userId: user.id, total: order.total,
  items: order.items.length, duration_ms: Date.now() - startTime,
});
// Output: {"level":"info","msg":"Order created","orderId":"ord_123",...}

// ❌ Unstructured — useless at scale
console.log(`Order created for user ${user.id} with total ${order.total}`);
```

## Log Levels

| Level | When | Production? |
|-------|------|------------|
| error | Requires immediate attention | ✅ Always |
| warn | Unexpected but handled | ✅ Always |
| info | Normal operations, audit trail | ✅ Always |
| debug | Dev troubleshooting | ❌ Dev only |

## Request ID Propagation

```typescript
// Middleware: assign request ID early
import { randomUUID } from 'node:crypto';

app.use((req, res, next) => {
  req.id = req.headers['x-request-id'] || randomUUID();
  res.setHeader('x-request-id', req.id);
  next();
});

// Every log entry includes it
app.use((req, res, next) => {
  logger.info('Request started', { method: req.method, path: req.path, request_id: req.id });
  const start = Date.now();
  res.on('finish', () => {
    logger.info('Request completed', {
      method: req.method, path: req.path, status: res.statusCode,
      duration_ms: Date.now() - start, request_id: req.id,
    });
  });
  next();
});
```

## Rules

```
✅ Request ID in every log entry (propagated via middleware)
✅ Log at layer boundaries (request in, response out, external call)
❌ Never log passwords, tokens, PII, or secrets
❌ Never use console.log in production code
```
