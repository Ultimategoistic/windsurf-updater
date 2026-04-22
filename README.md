# windsurf-updater

Automated update tool for Windsurf Editor (tarball installation) on any systemd-based Linux.

---

## Package Contents

```
windsurf-updater/
├── install.sh               ← Run this to set everything up
├── windsurf-update          ← The main update script
├── windsurf-update.service  ← Systemd service unit
└── windsurf-update.timer    ← Systemd timer (daily auto-update)
```

---

## Quick Start

### Step 1 — Copy this folder to the target machine

**Option A: USB drive or file manager**
Copy the entire `windsurf-updater/` folder to the target machine's home directory.

**Option B: SCP over SSH**
```bash
scp -r ~/windsurf-updater user@target-machine:~/windsurf-updater
```

**Option C: ZIP and transfer**
```bash
zip -r windsurf-updater.zip ~/windsurf-updater
# Transfer the zip, then on target machine:
unzip windsurf-updater.zip
```

---

### Step 2 — Run the installer on the target machine

```bash
cd ~/windsurf-updater
bash install.sh
```

That's it. The installer handles everything automatically.

---

## What the Installer Does

1. Checks that all required tools exist (`curl`, `grep`, `sort`, `tar`, etc.)
2. Creates `~/.local/bin/` and `~/.config/systemd/user/` if they don't exist
3. Copies `windsurf-update` to `~/.local/bin/` and makes it executable
4. Copies the systemd `.service` and `.timer` to `~/.config/systemd/user/`
5. Adds `~/.local/bin` to PATH in your shell profile if not already there
6. Enables and starts the systemd timer (auto-updates daily)
7. Creates the desktop entry (`windsurf.desktop`) if Windsurf is installed
8. Runs an initial version check so you see the current status

---

## Commands After Installation

```bash
windsurf-update check      # Check if a newer version is available
windsurf-update install    # Download and install the latest version
windsurf-update rollback   # Restore the previous backup
windsurf-update help       # Show all options
```

---

## Fresh Install (Windsurf not yet installed)

If Windsurf is not installed on the new machine, the installer will warn you. Then simply run:

```bash
windsurf-update install
```

This will download and install the latest Windsurf tarball automatically into `~/.var/app/Windsurf/`.

---

## Auto-Update Schedule

The systemd timer runs:
- **5 minutes after every boot**
- **Every 24 hours** while the machine is running

Update logs are saved to: `~/.config/windsurf-update.log`

To check timer status at any time:
```bash
systemctl --user list-timers windsurf-update.timer
```

---

## Uninstall

```bash
cd ~/windsurf-updater
bash install.sh --remove
```

This removes the script, systemd units, and log file.
Windsurf itself is **not** touched.

---

## Prerequisites

Already present on Shani OS and most Arch/Debian/Fedora based systems:

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

## File Paths (after installation)

| File | Path |
|---|---|
| Update script | `~/.local/bin/windsurf-update` |
| Systemd service | `~/.config/systemd/user/windsurf-update.service` |
| Systemd timer | `~/.config/systemd/user/windsurf-update.timer` |
| Desktop entry | `~/.local/share/applications/windsurf.desktop` |
| Log file | `~/.config/windsurf-update.log` |
| Windsurf install | `~/.var/app/Windsurf/` |
| Windsurf backup | `~/.var/app/Windsurf_old/` |
