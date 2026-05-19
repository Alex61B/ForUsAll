# API Reference — Employee Time-Off Tracking System

All endpoints are under `/api/v1` and follow the [JSON:API](https://jsonapi.org/) specification.

**Content-Type:** `application/vnd.api+json`

**Authentication:** Devise session cookie. Sign in via `POST /api/v1/sessions` to obtain a session.

---

## Sessions

### Sign In
`POST /api/v1/sessions`

**Body:**
```json
{ "user": { "email": "user@example.com", "password": "password123" } }
```

**200 OK:**
```json
{
  "data": {
    "type": "users",
    "id": "1",
    "attributes": { "email": "...", "full_name": "Jane Doe", "role": "employee" }
  },
  "meta": { "message": "Signed in successfully." }
}
```

**401 Unauthorized:** Invalid credentials.

### Sign Out
`DELETE /api/v1/sessions/:id`

**200 OK:** `{ "meta": { "message": "Signed out successfully." } }`

---

## Users

### List Users
`GET /api/v1/users` — Admin only. Returns all users ordered by last name.

### Get User
`GET /api/v1/users/:id` — Admin or the user themselves.

### Update User
`PATCH /api/v1/users/:id` — Admin or the user themselves. Non-admins cannot change `role`.

**Body:**
```json
{ "user": { "first_name": "Jane", "last_name": "Doe", "department_id": 2, "manager_id": 5 } }
```

---

## Departments

### List Departments
`GET /api/v1/departments` — Any authenticated user. Returns departments alphabetically.

### Get Department
`GET /api/v1/departments/:id` — Any authenticated user.

---

## Time-Off Requests

### List Requests
`GET /api/v1/time_off_requests`

Scoped by role:
- Employee: own requests only
- Manager: direct reports' requests
- Admin: all requests

**Query params:** `status` (pending/approved/denied/cancelled), `leave_type` (vacation/sick/personal), `page`

### Get Request
`GET /api/v1/time_off_requests/:id`

### Create Request
`POST /api/v1/time_off_requests`

**Body:**
```json
{
  "time_off_request": {
    "leave_type": "vacation",
    "start_date": "2026-06-01",
    "end_date": "2026-06-05",
    "reason": "Summer holiday"
  }
}
```

**201 Created** on success. **422 Unprocessable Entity** on validation failure.

### Update Request
`PATCH /api/v1/time_off_requests/:id` — Owner or admin; only pending requests.

### Cancel Request (HTML flow)
`DELETE /api/v1/time_off_requests/:id` — Sets status to cancelled. **204 No Content**.

### Approve Request
`POST /api/v1/time_off_requests/:id/approve` — Manager of requester or admin.

### Deny Request
`POST /api/v1/time_off_requests/:id/deny` — Manager of requester or admin.

### Cancel Request (explicit)
`POST /api/v1/time_off_requests/:id/cancel` — Owner, manager of requester, or admin; only pending.

---

## Approvals

### List Approvals
`GET /api/v1/approvals` — Admin or manager.

### Get Approval
`GET /api/v1/approvals/:id` — Admin, approving manager, or the employee whose request it belongs to.

---

## Error Responses

All errors follow JSON:API error format:

```json
{
  "errors": [
    { "title": "Unprocessable Entity", "detail": "Start date cannot be in the past", "source": { "pointer": "/data/attributes/start_date" } }
  ]
}
```

| Status | Meaning |
|--------|---------|
| 401    | Not authenticated |
| 403    | Authenticated but not authorized |
| 404    | Resource not found |
| 422    | Validation failure |
