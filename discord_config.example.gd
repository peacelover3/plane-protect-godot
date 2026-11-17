# Copy this file to `discord_config.gd` (same folder) and paste your webhook URL.
# `discord_config.gd` is gitignored, so the URL never gets committed.
#
# How to get a URL:
#   1. In Discord: Server Settings -> Integrations -> Webhooks -> New Webhook
#   2. Pick the channel, then "Copy Webhook URL"
#   3. Paste it below between the quotes.
#
# You can also point the game at a webhook without touching this file:
#   - Desktop dev:  set the SKY_WARDEN_WEBHOOK environment variable, or
#   - Any platform: create user://discord.cfg containing
#                       [discord]
#                       webhook="https://discord.com/api/webhooks/..."
extends RefCounted

const WEBHOOK_URL := ""
