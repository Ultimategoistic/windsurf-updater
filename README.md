# windsurf-updater

> Automated daily updates for [Windsurf Editor](https://windsurf.com) tarball installations on systemd-based Linux.


Windsurf only ships official packages for Debian (apt) and Fedora (dnf). If you're on **Arch, Void, Alpine, or any other distro** that installed Windsurf from a tarball — this tool keeps it up to date automatically, no manual downloads needed.

---

## Features

- 🔄 **Daily auto-updates** via a systemd user timer
- 🚀 **Runs 5 minutes after every boot** to catch missed updates
- 💾 **Automatic backup** before every update — rollback anytime
- 🖥️ **Desktop entry** created automatically if Windsurf is installed
- 🧹 **Clean uninstall** — removes everything it installed, never touches Windsurf itself

---

## Quick Install

```bash
git clone https://github.com/Ultimategoistic/windsurf-updater.git
cd windsurf-updater
bash install.sh
```

That's it. The installer sets everything up and runs an initial version check.

---

## Usage

```bash
windsurf-update check      # Check if a newer version is available
windsurf-update install    # Download and install the latest version
windsurf-update rollback   # Restore the previous backup
windsurf-update help       # Show all options
```

### Fresh install (Windsurf not yet on your machine)

```bash
bash install.sh            # sets up the updater
windsurf-update install    # downloads and installs Windsurf
```

---

## How It Works

When you run `install.sh`, it:

1. Verifies all required tools are present (`curl`, `grep`, `sort`, `tar`, `file`)
2. Installs `windsurf-update` to `~/.local/bin/`
3. Installs the systemd `.service` and `.timer` to `~/.config/systemd/user/`
4. Adds `~/.local/bin` to `$PATH` in your shell profile if needed
5. Enables and starts the daily timer
6. Creates a `.desktop` entry if Windsurf is already installed
7. Runs an initial version check

---

## Auto-Update Schedule

| Trigger | When |
|---|---|
| Boot | 5 minutes after login |
| Timer | Every 24 hours |

Logs are written to `~/.config/windsurf-update.log`.

```bash
# Check timer status
systemctl --user list-timers windsurf-update.timer

# View logs
cat ~/.config/windsurf-update.log
```

---

## Uninstall

```bash
bash install.sh --remove
```

Removes the script, systemd units, and log file. **Windsurf itself is not touched.**

---

## File Paths

| File | Path |
|---|---|
| Update script | `~/.local/bin/windsurf-update` |
| Systemd service | `~/.config/systemd/user/windsurf-update.service` |
| Systemd timer | `~/.config/systemd/user/windsurf-update.timer` |
| Desktop entry | `~/.local/share/applications/windsurf.desktop` |
| Log file | `~/.config/windsurf-update.log` |
| Windsurf install | `~/.var/app/Windsurf/` |
| Windsurf backup | `~/.var/app/Windsurf_old/` |

---

## Prerequisites

These are standard on most Linux distros:

| Tool | Purpose |
|---|---|
| `bash` ≥ 4.0 | Script runtime |
| `curl` | Download Windsurf tarball |
| `grep` (GNU, with `-P`) | Version string parsing |
| `sort` (GNU, with `-V`) | Version comparison |
| `tar` | Archive extraction |
| `file` | Validate downloaded archive |
| `systemd` user session | Timer / auto-update scheduling |

---

## Repository Structure

```
windsurf-updater/
├── install.sh               ← Run this to set everything up
├── windsurf-update          ← The main update script
├── windsurf-update.service  ← Systemd service unit
└── windsurf-update.timer    ← Systemd timer (daily auto-update)
```

---

## Contributing

Issues and PRs are welcome. If it works on your distro, feel free to open a PR adding it to the tested list below.

**Tested on:** Shani OS · Arch Linux · Void Linux

---

## License

[MIT](LICENSE)
