# Picoletter

Picoletter is a newsletter app for independent bloggers and writers. It uses [Resend](htttps://resend.com) APIs to send emails. With their really generous free tier, you could run your newsletter on a $5 VM on DigitalOcean or Hetzner virtually for free.

![compose](.github/screenshots/compose.webp)

<details>

<summary> More Screenshots </summary>

![design](.github/screenshots/design.webp)
![embed](.github/screenshots/embed.webp)
![published](.github/screenshots/published.webp)

</details>

This is beta software, you can use it in production if you're feeling like going on a adventure, meanwhile here are the list of things that work and things that are pending

## Features

- Run multiple newsletter from the same app
- Subscription, confirmation & unsubscription flow
- Schedule newsletter for sending
- Custom sending domains
- Handle bounces and complains to ensure good reputation
- Embeddable forms for subscription
- Public archive
- Subscriber reminders

### Pending features

- [ ] Subscriber import & export
- [ ] Subscriber labels and cohorts

## Stack

- Ruby on Rails
- PostgreSQl
- SolidQueue
- AWS SES
