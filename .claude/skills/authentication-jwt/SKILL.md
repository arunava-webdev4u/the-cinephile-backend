---
name: authentication-jwt
category: Development
applyTo:
  - patterns: ["lib/auth/**/*.rb"]
  - patterns: ["app/controllers/concerns/authenticable.rb"]
  - patterns: ["app/controllers/api/v1/auth_controller.rb"]
---

# JWT Authentication

## Files
- `lib/auth/json_web_token.rb` - Encode/decode tokens
- `app/controllers/concerns/authenticable.rb` - Controller integration
- `app/controllers/api/v1/auth_controller.rb` - Login endpoint

## Token Payload
```ruby
{
  user_id: user.id,
  email: user.email,
  jti: user.jti,  # JWT ID for revocation
  exp: expiration_timestamp
}
```

## Login
```ruby
token = JsonWebToken.encode(user_id: user.id, email: user.email, jti: user.jti)
# Response: { token: token, user: user_data }
```

## Logout (Revocation)
Update user's `jti` to invalidate old tokens:
```ruby
@current_user.update(jti: SecureRandom.uuid)
```

Verify in auth: Check `jti` matches database value

## Request Flow
1. Extract token from `Authorization: Bearer <token>` header
2. Decode & verify signature with `JWT_SECRET_KEY`
3. Check `jti` not revoked in database
4. Set `@current_user` from decoded `user_id`

## Security
- Use `JWT_SECRET_KEY` env var (never hardcode)
- Tokens expire in 24 hours
- HTTPS only in production
- Mock tokens in tests: `JsonWebToken.encode(user_id: user.id, jti: user.jti)`
