# Ruby Engineer Mini Project: Employee Time-Off Tracking System  

## Overview  
**Build an agentic workflow** that can be used to create software applications.  Use the workflow to create a Rails API-based employee time-off tracking system with a simple frontend. This project is a focused mini project designed to demonstrate key Rails skills while also showing how you can effectively use **Claude code / Codex** to accelerate development and maintain code quality.

Ideal workflow: Research -> Plan -> Implement -> Test **with deterministic backpressure** at each step to ensure each successful completion of the minimum requirements you define for each state.   

E.g.,
-Use agents/sub-agents or agent teams 
-Use skills/hooks 
-Ensure ruby best practices are implemented.   


The project is intentionally left **a little open-ended**: you can choose the exact approach for certain features, giving you space to be creative while still hitting the core requirements.  

This project also evaluates how you work with AI tools. You are expected to use AI intentionally and transparently as part of your development process (see requirements below).  

---

## Project Requirements  

### Core Features  
1. **Employee Management**  
   - Employees can register/login  
   - Basic profile (name, email, department, manager)  
   - Role-based access (Employee, Manager, Admin)  

2. **Time-Off Requests**  
   - Submit time-off requests (vacation, sick leave, personal)  
   - Specify date ranges and reason  
   - Track request status (pending, approved, denied)  
   - View request history  

3. **Approval Workflow**  
   - Managers approve/deny requests for direct reports  
   - Admins manage all requests  
   - Email notifications for status changes (mock or background job based)  

4. **API & Frontend**  
   - JSON:API compliant REST endpoints  
   - Simple HTML interface using Rails views (no React/Vue required)  
   - Basic styling with CSS/Bootstrap  

---

## Technical Requirements  

#### Backend (Rails 8+)  
- **Authentication**: Devise or a simple session-based auth  
- **Authorization**: Role-based permissions  
- **Database**: PostgreSQL with migrations  
- **API Design**: RESTful JSON endpoints  
- **Testing**: RSpec with coverage for core logic  
- **Background Jobs**: Sidekiq/ActiveJob for notifications  
- **Data Validation**: Rails validations + business rules  

> **AI-Assistance Angle**:  
> - Use AI tools to generate deterministic boilerplate (models, migrations, controllers, specs).  
> - Lean on AI for test scaffolding, seed data generation, and repetitive CRUD endpoints.  
> - Focus your manual effort on the “hard parts”: business logic, workflow correctness, and edge cases.  
> - **Use an agentic development process with back pressure to one-shot this application.**  
> - You must **save every single prompt used during development** (no exceptions), including iterative prompts, fixes, and refinements.  

---

#### Suggested Database Schema  
```ruby
# Suggested models (flexible — design your own if you prefer):
- User (employee info, role, manager relationships)
- TimeOffRequest (dates, type, status, reason)
- Department
- TimeOffType (vacation, sick, personal)
- Approval (audit trail)


# Example Business Logic
- Employees cannot request time off in the past  
- Overlapping requests should be flagged  
- Annual vacation day limits per employee  
- Approval rules may vary based on request duration  
- Manager hierarchy validation  
```

---

# Deliverables  

## Agentic workflow
- Skills/commands/hooks/scripts
- Be prepared to discuss how you defined and verified that requirements (e.g., gates) were completed at each step, artifacts created, etc.

## Rails Application  
- Functional app with migrations & seed data  
- AI-assisted boilerplate clearly committed in code history *(optional but encouraged)*  

## API Documentation  
- Swagger/OpenAPI spec or Markdown docs with examples  

## Tests  
- Model tests for validations/business rules  
- Request tests for endpoints  
- AI-assisted test generation encouraged  

## README  
- Setup instructions  
- Where AI-assisted coding was most useful  
- Trade-offs due to time constraints  
- Future improvements  
- **All prompts used during development (or link to `PROMPTS.md`) — this must include every prompt without omission**  
- **A clearly labeled example demonstrating your agentic “one-shot” development approach with back pressure**  

## Prompt Log (Required)  
- A `PROMPTS.md` (or equivalent) containing:  
  - **Every prompt used during development (required, no exceptions)**  
  - The tool used (e.g., Cursor, Copilot, Claude)  
  - *(Optional)* resulting outputs  
  - A clearly labeled example demonstrating your **agentic one-shot approach with back pressure**  


