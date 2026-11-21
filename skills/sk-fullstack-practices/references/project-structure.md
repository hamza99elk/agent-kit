# Project Structure & Configuration

Load this reference when implementing the project directory layout, three-layer architecture, dependency injection, or configuration management.

---

## Feature-First Organization

```
✅ Feature-first                    ❌ Layer-first
src/                                src/
  orders/                             controllers/
    order.controller.ts                 order.controller.ts
    order.service.ts                    user.controller.ts
    order.repository.ts               services/
    order.dto.ts                        order.service.ts
    order.test.ts                       user.service.ts
  users/                              repositories/
    user.controller.ts                  ...
    user.service.ts
  shared/
    database/
    middleware/
```

## Three-Layer Architecture

```
Controller (HTTP) → Service (Business Logic) → Repository (Data Access)
```

| Layer | Responsibility | ❌ Never |
|-------|---------------|---------|
| Controller | Parse request, validate, call service, format response | Business logic, DB queries |
| Service | Business rules, orchestration, transaction mgmt | HTTP types (req/res), direct DB |
| Repository | Database queries, external API calls | Business logic, HTTP types |

## Dependency Injection (All Languages)

**TypeScript:**
```typescript
class OrderService {
  constructor(
    private readonly orderRepo: OrderRepository,    // ✅ injected interface
    private readonly emailService: EmailService,
  ) {}
}
```

**Python:**
```python
class OrderService:
    def __init__(self, order_repo: OrderRepository, email_service: EmailService):
        self.order_repo = order_repo                 # ✅ injected
        self.email_service = email_service
```

**Go:**
```go
type OrderService struct {
    orderRepo    OrderRepository                      // ✅ interface
    emailService EmailService
}

func NewOrderService(repo OrderRepository, email EmailService) *OrderService {
    return &OrderService{orderRepo: repo, emailService: email}
}
```

## Configuration

### Centralized, Typed, Fail-Fast

**TypeScript:**
```typescript
const config = {
  port: parseInt(process.env.PORT || '3000', 10),
  database: { url: requiredEnv('DATABASE_URL'), poolSize: intEnv('DB_POOL_SIZE', 10) },
  auth: { jwtSecret: requiredEnv('JWT_SECRET'), expiresIn: process.env.JWT_EXPIRES_IN || '1h' },
} as const;

function requiredEnv(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required env var: ${name}`);  // fail fast
  return value;
}
```

**Python:**
```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str                        # required — app won't start without it
    jwt_secret: str                          # required
    port: int = 3000                         # optional with default
    db_pool_size: int = 10
    class Config:
        env_file = ".env"

settings = Settings()                        # fails fast if DATABASE_URL missing
```

### Rules

```
✅ All config via environment variables (Twelve-Factor)
✅ Validate required vars at startup — fail fast
✅ Type-cast at config layer, not at usage sites
✅ Commit .env.example with dummy values

❌ Never hardcode secrets, URLs, or credentials
❌ Never commit .env files
❌ Never scatter process.env / os.environ throughout code
```
