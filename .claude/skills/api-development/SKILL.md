---
name: api-development
category: Development
applyTo:
  - patterns: ["app/controllers/api/v1/**/*_controller.rb"]
  - patterns: ["app/serializers/**/*_serializer.rb"]
---

# API Development

## Controllers (`app/controllers/api/v1/`)

**Plural resources**: RESTful - index, show, create, update, destroy
```ruby
class Api::V1::ListsController < ApplicationController
  before_action :authenticate_user!
  def index; @current_user.lists; end
  def create; list.save ? render_json(list, :created) : errors; end
end
```

**Singular resources**: No ID param, use `@current_user`
```ruby
class Api::V1::UserController < ApplicationController
  before_action :authenticate_user!
  def show; render_json(@current_user); end
  def update; @current_user.update(user_params) ? ... : errors; end
end
```

Routes: `resources :lists` (plural), `resource :user` (singular)

## Authorization Pattern
```ruby
def authorize_resource!
  unless resource.user_id == @current_user.id
    render json: { error: "Not authorized" }, status: :forbidden
  end
end
```

## Serializers (`app/serializers/`)
```ruby
class ListSerializer < ActiveModel::Serializer
  attributes :id, :name
  has_many :list_items
  belongs_to :user
end
```

## Response Format

**Success**: Resource JSON or array
**Validation (422)**: `{"errors": {"field": ["message"]}}`
**Auth (401)**: `{"error": "Unauthorized"}`
**Forbidden (403)**: `{"error": "Not authorized"}`
**Not found (404)**: `{"error": "Resource not found"}`

## Nested Routes
`/api/v1/custom_list/:id/list_items` - set list, authorize, return items

## Common
- Include auth headers: `Authorization: Bearer <token>`
- Prevent N+1: `.includes(:associations)`
- Mock TMDB calls in tests
