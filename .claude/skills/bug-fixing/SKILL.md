---
name: bug-fixing
category: Development
applyTo:
  - patterns: ["BUG_REPORT_*.md"]
---

# Bug Fixes

## Issue 1: Missing ListItem Validations

**File**: `app/models/list_item.rb`
**Problem**: No validations → DB errors instead of validation errors

Fix:
```ruby
validates :item_id, presence: true, uniqueness: { scope: :list_id }
validates :item_type, presence: true, inclusion: { in: %w(Movie TvShow) }
```

## Issue 2: Missing Authorization in ListItemsController

**File**: `app/controllers/api/v1/list_items_controller.rb`
**Problem**: No authorization → users can access other users' items (security bug)

Fix: Add `before_action :authorize_list!` and check `@list.user_id == @current_user.id`

## Issue 3: Inconsistent Error Responses

**Problem**: Different error formats across endpoints

Fix: Standardize to:
- Validation: `{"errors": {"field": ["message"]}}`
- Auth: `{"error": "Unauthorized"}`
- Not found: `{"error": "Resource not found"}`

## Workflow
1. Write failing test
2. Implement fix
3. Verify all tests pass
4. Verify no DB errors reach API
5. Run: `bundle exec rspec && bin/brakeman && bin/rubocop`

## Priority
1. Authorization checks (security)
2. ListItem validations (data integrity)
3. Error response consistency (API quality)
