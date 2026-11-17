# Sky Warden

A small mobile arcade game. Fly over the battlefield, bomb the ground forces trying to reach the
Beacon, and keep it lit. Three planes, four records, one angry King.

Built with **Godot 4.7** (GL Compatibility). No external assets, no plugins, no ads, no analytics.

## Run it

```bash
godot --path .                 # run the game
godot -e --path .              # open it in the editor
```

Desktop controls:

- **Drag with the mouse** on the left side of the screen to use the floating stick.
- **WASD / arrow keys** also fly the plane.
- **Esc** pauses.

On a phone the same stick follows your thumb.

## How the game works

- **Bombs are automatic.** They drop under the plane; the plane turns to face where it is flying.
  Explosions also destroy enemy fireballs.
- **Three planes.** An enemy reaching the Beacon, or a fireball hitting you, costs one. You respawn
  with a moment of invulnerability.
- **Four records.** Each level is a run: hit the score target before the timer. Clearing a level
  shows the next note and unlocks the next record.
- **The notes are the point.** Levels 1–4 each show one of the notes written for the Queen, and
  beating the King shows the last one.
- **King of MathLand.** After four records, the King fights: a hovering boss with its own health,
  fireball volleys and minion drops.
- **Free For All.** Beat the King to unlock endless mode. No timer, no target. Enemies get faster and
  more numerous until you lose all three planes.
- **Difficulty.** Easy, Normal and Hard live in Settings and change score targets, spawn rate,
  enemy speed, flak and the King's health.

Send a note to the dev **only after beating the King**, from the ending screen. It goes straight to
Discord.

Progress (cleared records, records, endless best, King status, difficulty, sound) is saved to
`user://sky_warden_save.cfg`. **Settings → Reset all data** wipes it after a second tap.

## Connect Discord

Player notes are posted to a Discord webhook. Nothing is sent until you configure one.

1. In Discord: **Server Settings → Integrations → Webhooks → New Webhook**, pick a channel, **Copy
   Webhook URL**.
2. Copy the template and paste the URL inside the quotes:

   ```bash
   cp discord_config.example.gd discord_config.gd
   ```

   ```gdscript
   const WEBHOOK_URL := "https://discord.com/api/webhooks/...."
   ```

`discord_config.gd` is gitignored, so the URL is never committed.

Alternatives, checked first to last:

- environment variable `SKY_WARDEN_WEBHOOK`, then
- `user://discord.cfg` containing `[discord]` / `webhook="https://..."`, then
- `res://discord_config.gd`.

## Tuning

The four level definitions live at the top of `scripts/game_state.gd` in `LEVELS`. Difficulty
multipliers are the `target_scale`, `spawn_scale`, `speed_scale`, `flak_adjust` and `boss_hp`
functions next to them. Bomb cadence (`BOMB_INTERVAL`), blast radius (`bomb.gd`) and plane speed
(`plane.gd`) are the other main knobs. Endless ramps its spawn rate every 20 seconds in
`scripts/game.gd`.

## Building for a phone

1. Install the Android build template from the editor (**Editor → Manage Export Templates**).
2. Set up Android export with your SDK path and a debug keystore.
3. **Project → Export → Android**, then export an APK and install it.

The project is set to landscape, 1280×720 with `canvas_items` stretching, and touch emulating mouse
so the buttons work on a phone. iOS export works the same way on a Mac.

## Tests

A headless harness drives the real scene: four levels, the note pages, pause/resume, plane turning,
settings, difficulty scaling, the King, Free For All, reset, and screen fit at 720 px.

```bash
godot --headless --fixed-fps 60 res://tests/test_harness.tscn
```

It exits non-zero on failure and restores your save file.

## Project layout

```
scenes/main.tscn        root scene
scripts/main.gd         menu, settings, notes, results, ending, scene flow
scripts/game.gd         arena: levels, boss, endless, hearts, bombing
scripts/game_state.gd   save data, four levels, difficulty
scripts/plane.gd        movement, turning, shadow
scripts/enemy.gd        walkers and flak turrets
scripts/bomb.gd         falling bomb
scripts/fireball.gd     homing flak projectile
scripts/boss.gd         King of MathLand
scripts/beacon.gd       the building
scripts/field.gd        battlefield
scripts/hud.gd          hearts, score, timer, boss bar
scripts/joystick.gd     floating stick
scripts/lore.gd         the notes from notes.txt
scripts/sfx.gd          synthesised sound effects
scripts/discord_service.gd  webhook delivery
scripts/ui_kit.gd       palette, theme, cards, buttons
assets/art/*.svg        original vector art
notes.txt               the notes, kept as written
```

All art is original SVG; all sound is synthesised at runtime.
