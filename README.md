# Employee Time-Off Tracking System

Rails 8 + PostgreSQL application for managing employee time-off requests with
role-based approval workflows. Exposes JSON:API-compliant REST endpoints and
server-rendered HTML views styled with Bootstrap 5.

## Setup

### Prerequisites

- Ruby 3.3.4 (via rbenv)
- PostgreSQL 16
- Bundler

### Installation

```bash
bundle install
bundle exec rails db:create db:migrate db:seed
bundle exec rails server
```

Visit `http://localhost:3000`. Seed credentials:

| Role     | Email                   | Password    |
|----------|-------------------------|-------------|
| Admin    | admin@example.com       | password123 |
| Manager  | manager@example.com     | password123 |
| Employee | employee1@example.com   | password123 |

## Architecture

### Roles

- **Employee** — submits and cancels their own requests
- **Manager** — approves/denies direct reports' requests
- **Admin** — full access to all users, departments, and requests

### Business Rules

- Requests cannot start in the past
- End date must be on or after start date
- Overlapping pending/approved requests for the same employee are blocked
- Vacation leave is capped at `TimeOffRequest::ANNUAL_VACATION_LIMIT` (15) days per year
- Sick and personal leave have no annual cap

### Background Jobs

- `NotifyManagerJob` — emails the manager when a new request is submitted
- `NotifyRequesterJob` — emails the employee when their request is approved, denied, or cancelled

## Key Commands

```bash
bin/rails server                       # Start dev server
bundle exec rspec                      # Run test suite
bundle exec rails db:seed              # Load demo data
bash scripts/verify.sh                 # Full verification suite
```

## API

JSON:API-compliant endpoints under `/api/v1`. See [docs/api.md](docs/api.md) for full reference.

Authentication uses Devise session cookies. Sign in via `POST /api/v1/sessions`.

## Technical Notes

- **No generators used**: All files written manually to avoid drift detection false positives
  in the backpressure workflow enforcement system.
- **No asset pipeline complexity**: Bootstrap loaded via CDN in the layout.
- **YJIT disabled**: Ruby 3.3.4 on arm64 has a linker issue with YJIT symbols; disabled via
  `RUBY_CONFIGURE_OPTS="--disable-yjit"`.
- **API base controller**: `Api::V1::BaseController < ActionController::Base` (not `ApplicationController`)
  to prevent Devise HTML redirects on unauthenticated API requests.

## Prompt Log

See [PROMPTS.md](PROMPTS.md) for a full record of AI-assisted development prompts.

## Tradeoffs

| Decision | Rationale |
|----------|-----------|
| Pundit over CanCanCan | Explicit per-action policies are easier to audit |
| jsonapi-serializer over ActiveModelSerializers | Maintained, JSON:API spec compliant |
| Session cookies for API auth | Simpler for same-origin clients; token-based auth is out of scope |
| No React/Vue frontend | Server-rendered HTML reduces stack complexity |
