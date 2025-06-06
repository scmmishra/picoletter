# Picoletter

Picoletter is a newsletter app for independent bloggers and writers. It uses SES to send emails. With their really generous free tier, you could run your newsletter on a $5 VM on DigitalOcean or Hetzner virtually for free.

![compose](.github/screenshots/compose.webp)

<details>

<summary> More Screenshots </summary>

![design](.github/screenshots/design.webp)
![embed](.github/screenshots/embed.webp)
![published](.github/screenshots/published.webp)

</details>

This is beta software, you can use it in production if you're feeling like going on a adventure, meanwhile here are the list of things that work and things that are pending

## Features

- Run multiple newsletters from the same app
- Subscription, confirmation & unsubscription flow
- Schedule newsletter for sending
- Custom sending domains with DNS verification
- Handle bounces and complaints to ensure good reputation
- Embeddable forms for subscription
- Public archive
- Subscriber reminders
- Subscriber labeling and categorization
- Email analytics tracking (opens, clicks)

### Pending features

- [ ] Subscriber import & export

## Stack

- Ruby on Rails
- PostgreSQL
- SolidQueue (background jobs)
- AWS SES (email delivery)
- Tailwind CSS (styling)
- Hotwire/Turbo (dynamic interactions)

## Getting Started

### Prerequisites
- Ruby 3.1+
- PostgreSQL
- AWS SES account

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   bundle install
   ```
3. Set up the database:
   ```bash
   bundle exec rails db:setup
   ```
4. Start the server:
   ```bash
   overmind start Procfile.dev
   ```

### Testing

Run the test suite:
```bash
bundle exec rspec
```

Run linting:
```bash
bundle exec rubocop
```
