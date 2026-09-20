# API Interface & Contract Standards

Canonical design standards for public and internal APIs.

---

## 1. REST Endpoint Conventions
- Resource names are plural nouns in kebab-case: `/v1/user-profiles`, `/v1/orders/{order_id}/items`.
- HTTP Verbs map strictly to action semantics:
  - `GET`: Safe, idempotent read.
  - `POST`: Create resource or trigger action.
  - `PUT`: Complete idempotent replacement.
  - `PATCH`: Partial modification.
  - `DELETE`: Idempotent removal.

## 2. Standard Error Envelope
All error responses (4xx and 5xx) must adhere to the standard envelope:
```json
{
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "The payload contains invalid parameters.",
    "details": [
      {
        "field": "email",
        "issue": "Must be a valid RFC 5322 email address"
      }
    ]
  }
}
```

## 3. Idempotency Specification
- Clients provide an `Idempotency-Key: <UUIDv4>` header on POST requests.
- Server caches the response key in Redis/DB for 24 hours.
- Duplicate requests in-flight return `409 Conflict` or wait for the initial request.
- Subsequent identical requests return the cached HTTP status code and response body with `Idempotent-Replayed: true`.

## 4. Pagination Formats

### Cursor-Based (Default for high-volume or real-time collections)
Query parameters: `?limit=50&cursor=eyJpZCI6MTIzfQ`
Response payload:
```json
{
  "data": [...],
  "pagination": {
    "limit": 50,
    "next_cursor": "eyJpZCI6MTczfQ",
    "has_more": true
  }
}
```

### Offset-Based (For admin search tables)
Query parameters: `?page=1&per_page=25`
Response payload:
```json
{
  "data": [...],
  "pagination": {
    "page": 1,
    "per_page": 25,
    "total_records": 1042,
    "total_pages": 42
  }
}
```

## 5. Security & Rate Limiting Headers
- Rate limit headers returned on all responses:
  - `X-RateLimit-Limit`: Maximum allowed requests in window.
  - `X-RateLimit-Remaining`: Remaining requests in current window.
  - `X-RateLimit-Reset`: Unix epoch timestamp when window resets.
