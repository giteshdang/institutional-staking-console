# Backend (Rails API)

See the root `README.md` for API behavior, formulas, assumptions, Docker instructions, and verification details.

```bash
bundle install
bin/rails db:prepare
bin/rails db:seed
bin/rails s -p 3000
```

API key from seeds: `demo-key` (`X-Api-Key`).

Run tests with `bundle exec rspec`.
