#!/usr/bin/env bash
#
# install.sh - Installer for windsurf-update automation
# Run this script once on any machine to set up Windsurf auto-updates.
#
# Usage:
#   bash install.sh           - Install everything
#   bash install.sh --remove  - Remove everything installed by this script
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BIN_DIR="${HOME}/.local/bin"
SYSTEMD_DIR="${HOME}/.config/systemd/user"
APPS_DIR="${HOME}/.local/share/applications"
WINDSURF_INSTALL_DIR="${HOME}/.var/app/Windsurf"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}  →${NC} $*"; }
success() { echo -e "${GREEN}  ✓${NC} $*"; }
warn()    { echo -e "${YELLOW}  !${NC} $*"; }
error()   { echo -e "${RED}  ✗${NC} $*" >&2; }
header()  { echo -e "\n${BOLD}$*${NC}"; }

# ============================================================================
# CHECKS
# ============================================================================

check_prerequisites() {
    header "Checking prerequisites..."
    local missing=0

    for cmd in bash curl grep sort tar file systemctl; do
        if command -v "${cmd}" &>/dev/null; then
            success "${cmd} found"
        else
            error "${cmd} not found — please install it first"
            missing=1
        fi
    done

    # Check grep supports -P (PCRE)
    if echo "test" | grep -qP "test" 2>/dev/null; then
        success "grep -P (PCRE) supported"
    else
        error "grep does not support -P flag (need GNU grep)"
        missing=1
    fi

    # Check sort supports -V (version sort)
    if sort --version 2>&1 | grep -q "GNU"; then
        success "sort -V (GNU coreutils) supported"
    else
        warn "Could not confirm GNU sort — version sorting may not work correctly"
    fi

    if [[ ${missing} -ne 0 ]]; then
        echo ""
        error "Some prerequisites are missing. Please install them and re-run."
        exit 1
    fi
}

check_source_files() {
    header "Checking source files..."
    local missing=0

    for f in windsurf-update windsurf-update.service windsurf-update.timer; do
        if [[ -f "${SCRIPT_DIR}/${f}" ]]; then
            success "Found: ${f}"
        else
            error "Missing: ${SCRIPT_DIR}/${f}"
            missing=1
        fi
    done

    if [[ ${missing} -ne 0 ]]; then
        echo ""
        error "Source files are missing from ${SCRIPT_DIR}. Re-download the package."
        exit 1
    fi
}

# ============================================================================
# INSTALL
# ============================================================================

do_install() {
    check_prerequisites
    check_source_files

    # ── Step 1: Create directories ───────────────────────────────────────────
    header "Creating directories..."
    mkdir -p "${BIN_DIR}" "${SYSTEMD_DIR}" "${APPS_DIR}"
    success "Directories ready"

    # ── Step 2: Install the update script ────────────────────────────────────
    header "Installing windsurf-update script..."
    cp "${SCRIPT_DIR}/windsurf-update" "${BIN_DIR}/windsurf-update"
    chmod +x "${BIN_DIR}/windsurf-update"
    success "Installed → ${BIN_DIR}/windsurf-update"

    # ── Step 3: Install systemd units ────────────────────────────────────────
    header "Installing systemd units..."
    cp "${SCRIPT_DIR}/windsurf-update.service" "${SYSTEMD_DIR}/windsurf-update.service"
    cp "${SCRIPT_DIR}/windsurf-update.timer"   "${SYSTEMD_DIR}/windsurf-update.timer"
    success "Installed → ${SYSTEMD_DIR}/windsurf-update.service"
    success "Installed → ${SYSTEMD_DIR}/windsurf-update.timer"

    # ── Step 4: Check PATH ────────────────────────────────────────────────────
    header "Checking PATH..."
    if echo "${PATH}" | grep -q "${BIN_DIR}"; then
        success "${BIN_DIR} is already in PATH"
    else
        warn "${BIN_DIR} is not in PATH — adding to shell profile"
        local profile_file
        if [[ -f "${HOME}/.zshrc" ]]; then
            profile_file="${HOME}/.zshrc"
        else
            profile_file="${HOME}/.bashrc"
        fi
        echo "" >> "${profile_file}"
        echo '# Added by windsurf-updater install.sh' >> "${profile_file}"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${profile_file}"
        success "Added to ${profile_file} — run: source ${profile_file}"
    fi

    # ── Step 5: Enable systemd timer ─────────────────────────────────────────
    header "Enabling systemd timer..."
    systemctl --user daemon-reload
    systemctl --user enable --now windsurf-update.timer
    success "Timer enabled and started"

    # ── Step 6: Create desktop entry if Windsurf is installed ────────────────
    header "Checking Windsurf installation..."
    if [[ -f "${WINDSURF_INSTALL_DIR}/windsurf" ]]; then
        success "Windsurf found at ${WINDSURF_INSTALL_DIR}"

        local desktop_file="${APPS_DIR}/windsurf.desktop"
        if [[ ! -f "${desktop_file}" ]]; then
            info "Creating desktop entry..."
            cat > "${desktop_file}" << EOF
[Desktop Entry]
Name=Windsurf
Comment=AI-powered IDE and Agentic Coding Environment
Exec=${WINDSURF_INSTALL_DIR}/windsurf
Icon=windsurf
Terminal=false
Type=Application
Categories=Development;IDE;
StartupWMClass=Windsurf
EOF
            success "Desktop entry created → ${desktop_file}"
        else
            info "Desktop entry already exists — skipping"
        fi
    else
        warn "Windsurf not found at ${WINDSURF_INSTALL_DIR}"
        warn "Run: windsurf-update install   to download and install Windsurf"
    fi

    # ── Done ──────────────────────────────────────────────────────────────────
    echo ""
    echo -e "${GREEN}${BOLD}══════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}  Installation complete!${NC}"
    echo -e "${GREEN}${BOLD}══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${BOLD}Commands available:${NC}"
    echo -e "    ${BLUE}windsurf-update check${NC}      — check for updates"
    echo -e "    ${BLUE}windsurf-update install${NC}    — install latest version"
    echo -e "    ${BLUE}windsurf-update rollback${NC}   — restore previous version"
    echo ""
    echo -e "  ${BOLD}Auto-update:${NC} runs daily via systemd timer"
    echo -e "  ${BOLD}Log file:${NC}    ${HOME}/.config/windsurf-update.log"
    echo ""

    # Run first check
    header "Running initial version check..."
    "${BIN_DIR}/windsurf-update" check
}

# ============================================================================
# REMOVE
# ============================================================================

do_remove() {
    header "Removing windsurf-update automation..."

    # Stop and disable timer
    if systemctl --user is-active windsurf-update.timer &>/dev/null; then
        systemctl --user stop windsurf-update.timer
        success "Timer stopped"
    fi
    if systemctl --user is-enabled windsurf-update.timer &>/dev/null; then
        systemctl --user disable windsurf-update.timer
        success "Timer disabled"
    fi

    # Remove files
    for f in \
        "${BIN_DIR}/windsurf-update" \
        "${SYSTEMD_DIR}/windsurf-update.service" \
        "${SYSTEMD_DIR}/windsurf-update.timer" \
        "${HOME}/.config/windsurf-update.log"
    do
        if [[ -f "${f}" ]]; then
            rm -f "${f}"
            success "Removed: ${f}"
        fi
    done

    systemctl --user daemon-reload
    success "Systemd daemon reloaded"

    echo ""
    success "windsurf-update has been fully removed."
    warn "Windsurf itself was NOT removed. Your installation is untouched."
    echo ""
}

# ============================================================================
# ENTRY POINT
# ============================================================================

case "${1:-install}" in
    --remove|-r)   do_remove  ;;
    --install|-i)  do_install ;;
    *)             do_install ;;
esac
