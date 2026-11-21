# Database Access Patterns

Load this reference when implementing database access, querying, migrations, or connection management.

---

## Migrations Always

```bash
# TypeScript (Prisma)           # Python (Alembic)              # Go (golang-migrate)
npx prisma migrate dev          alembic revision --autogenerate  migrate -source file://migrations
npx prisma migrate deploy       alembic upgrade head             migrate -database $DB up
```

```
✅ Schema changes via migrations, never manual SQL
✅ Migrations must be reversible
✅ Review migration SQL before production
❌ Never modify production schema manually
```

## N+1 Prevention

```typescript
// ❌ N+1: 1 query + N queries
const orders = await db.order.findMany();
for (const o of orders) { o.items = await db.item.findMany({ where: { orderId: o.id } }); }

// ✅ Single JOIN query
const orders = await db.order.findMany({ include: { items: true } });
```

## Transactions for Multi-Step Writes

```typescript
await db.$transaction(async (tx) => {
  const order = await tx.order.create({ data: orderData });
  await tx.inventory.decrement({ productId, quantity });
  await tx.payment.create({ orderId: order.id, amount });
});
```

## Connection Pooling

Pool size = `(CPU cores × 2) + spindle_count` (start with 10-20). Always set connection timeout. Use PgBouncer for serverless.
