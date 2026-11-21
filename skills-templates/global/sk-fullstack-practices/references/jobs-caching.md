# Background Jobs & Caching

Load this reference when implementing background job processing, retry logic, or caching.

---

## Background Jobs

### Rules

```
✅ All jobs must be IDEMPOTENT (same job running twice = same result)
✅ Failed jobs → retry (max 3) → dead letter queue → alert
✅ Workers run as SEPARATE processes (not threads in API server)

❌ Never put long-running tasks in request handlers
❌ Never assume job runs exactly once
```

### Idempotent Job Pattern

```typescript
async function processPayment(data: { orderId: string }) {
  const order = await orderRepo.findById(data.orderId);
  if (order.paymentStatus === 'completed') return;  // already processed
  await paymentGateway.charge(order);
  await orderRepo.updatePaymentStatus(order.id, 'completed');
}
```

## Caching

### Cache-Aside (Lazy Loading)

```typescript
async function getUser(id: string): Promise<User> {
  const cached = await redis.get(`user:${id}`);
  if (cached) return JSON.parse(cached);

  const user = await userRepo.findById(id);
  if (!user) throw new NotFoundError('User', id);

  await redis.set(`user:${id}`, JSON.stringify(user), 'EX', 900);  // 15min TTL
  return user;
}
```

### Rules

```
✅ ALWAYS set TTL — never cache without expiry
✅ Invalidate on write (delete cache key after update)
✅ Use cache for reads, never for authoritative state

❌ Never cache without TTL (stale data is worse than slow data)
```

| Data Type | Suggested TTL |
|-----------|---------------|
| User profile | 5-15 min |
| Product catalog | 1-5 min |
| Config / feature flags | 30-60 sec |
| Session | Match session duration |
