# .claude Directory

Minimal Claude Code configuration for The Cinephile Backend.

## Structure

```
.claude/
├── skills/
│   ├── rails-testing/SKILL.md      # RSpec testing patterns
│   ├── api-development/SKILL.md    # RESTful API patterns
│   ├── authentication-jwt/SKILL.md # JWT implementation
│   └── bug-fixing/SKILL.md         # Bug fixes & issues
├── hooks/
│   └── SETUP.md                    # Initial setup checklist
└── agents/                         # (Placeholder)
```

## Quick Reference

- **CLAUDE.md** - Start here (project overview + architecture)
- **SETUP.md** - First-time environment setup
- **SKILL.md files** - Auto-loaded by file patterns

## Skills

Auto-triggered based on file type:

- `rails-testing` → `*_spec.rb` files
- `api-development` → `app/controllers/api/v1/` & serializers
- `authentication-jwt` → `lib/auth/` & auth controllers
- `bug-fixing` → `BUG_REPORT_*.md` files

## Key Commands

```bash
bundle exec rspec              # Tests
bin/rails s                    # Dev server
bin/rails db:migrate           # Migrations
bin/brakeman                   # Security
bin/rubocop                    # Lint
```

All documentation committed to GitHub (not sensitive).

