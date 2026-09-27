#!/usr/bin/env bash

set -uo pipefail

# Samuel-Mencke/dotfiles installer
# Based on 43PR/dotfiles
# Arch-compatible Linux + Hyprland

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
BACKUP_ROOT="$HOME/.config-backups"
TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

info() {
    printf '\n\033[1;34m[INFO]\033[0m %s\n' "$1"
}

success() {
    printf '\n\033[1;32m[DONE]\033[0m %s\n' "$1"
}

warning() {
    printf '\n\033[1;33m[WARN]\033[0m %s\n' "$1"
}

error() {
    printf '\n\033[1;31m[ERROR]\033[0m %s\n' "$1" >&2
}

# --------------------------------------------------
# Checks
# --------------------------------------------------

if [[ "${EUID}" -eq 0 ]]; then
    error "Do not run this script as root."
    exit 1
fi

if [[ ! -f /etc/os-release ]]; then
    error "Cannot determine the operating system."
    exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release

if [[ "${ID:-}" != "arch" && "${ID_LIKE:-}" != *arch* ]]; then
    error "This installer is intended for Arch-compatible Linux distributions."
    error "Detected: ${PRETTY_NAME:-unknown}"
    exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
    error "sudo is required."
    exit 1
fi

if ! command -v pacman >/dev/null 2>&1; then
    error "pacman was not found."
    exit 1
fi

PACKAGE_FILE="$REPO_DIR/packages.txt"
if [[ ! -f "$PACKAGE_FILE" ]]; then
    error "packages.txt not found."
    exit 1
fi

# --------------------------------------------------
# Package manager detection
# --------------------------------------------------

AUR_HELPER=""
if command -v paru >/dev/null 2>&1; then
    AUR_HELPER="paru"
elif command -v yay >/dev/null 2>&1; then
    AUR_HELPER="yay"
fi

info "Detected distribution: ${PRETTY_NAME:-unknown}"

if [[ -n "$AUR_HELPER" ]]; then
    info "AUR helper available: $AUR_HELPER"
else
    info "No AUR helper found. Bootstrapping yay..."

    if sudo pacman -S --needed --noconfirm git base-devel; then
        YAY_BUILD_DIR="$(mktemp -d)"
        if git clone https://aur.archlinux.org/yay.git "$YAY_BUILD_DIR/yay" \
            && (cd "$YAY_BUILD_DIR/yay" && makepkg -si --noconfirm); then
            AUR_HELPER="yay"
            success "yay installed."
        else
            warning "Failed to build/install yay automatically."
        fi
        rm -rf "$YAY_BUILD_DIR"
    else
        warning "Failed to install git/base-devel; AUR-only packages will be skipped."
    fi
fi

# --------------------------------------------------
# Packages
# --------------------------------------------------

mapfile -t PACKAGES < <(grep -vE '^[[:space:]]*(#|$)' "$PACKAGE_FILE")
OFFICIAL_PACKAGES=()
AUR_PACKAGES=()
UNKNOWN_PACKAGES=()

if [[ "${#PACKAGES[@]}" -eq 0 ]]; then
    warning "packages.txt does not contain any packages."
else
    info "Resolving packages..."

    for pkg in "${PACKAGES[@]}"; do
        if pacman -Si "$pkg" >/dev/null 2>&1; then
            OFFICIAL_PACKAGES+=("$pkg")
        elif [[ -n "$AUR_HELPER" ]] && "$AUR_HELPER" -Si "$pkg" >/dev/null 2>&1; then
            AUR_PACKAGES+=("$pkg")
        else
            UNKNOWN_PACKAGES+=("$pkg")
        fi
    done

    if [[ "${#OFFICIAL_PACKAGES[@]}" -gt 0 ]]; then
        info "Installing official-repo packages..."
        if sudo pacman -Syu --needed --noconfirm "${OFFICIAL_PACKAGES[@]}"; then
            success "Official-repo packages installed."
        else
            warning "pacman reported an error. Continuing so the backup/install can still complete."
        fi
    fi

    if [[ "${#AUR_PACKAGES[@]}" -gt 0 && -n "$AUR_HELPER" ]]; then
        info "Installing AUR packages with $AUR_HELPER..."
        if "$AUR_HELPER" -S --needed --noconfirm "${AUR_PACKAGES[@]}"; then
            success "AUR packages installed."
        else
            warning "$AUR_HELPER reported an error. Continuing."
        fi
    fi

    if [[ "${#UNKNOWN_PACKAGES[@]}" -gt 0 ]]; then
        warning "Unresolved packages: ${UNKNOWN_PACKAGES[*]}"
    fi
fi

# --------------------------------------------------
# Login shell
# --------------------------------------------------

info "Preserving current login shell: ${SHELL:-unknown}"

# --------------------------------------------------
# Backup existing configuration
# --------------------------------------------------

mkdir -p "$CONFIG_DIR" "$BACKUP_DIR"
info "Backing up config paths that this repo will replace..."

for item in "$REPO_DIR/.config/"*; do
    [[ -e "$item" ]] || continue
    name="$(basename "$item")"
    target="$CONFIG_DIR/$name"

    if [[ -e "$target" || -L "$target" ]]; then
        if [[ -L "$target" ]]; then
            # Preserve the actual linked contents so rollback does not depend on
            # the original symlink target still existing.
            cp -aL "$target" "$BACKUP_DIR/$name"
        else
            cp -a "$target" "$BACKUP_DIR/"
        fi

        # Remove the old path before copying. This prevents cp from following an
        # existing symlink and modifying an external config tree such as ML4W.
        rm -rf -- "$target"
    fi
done

if [[ -e "$HOME/.zshrc" || -L "$HOME/.zshrc" ]]; then
    if [[ -L "$HOME/.zshrc" ]]; then
        cp -aL "$HOME/.zshrc" "$BACKUP_DIR/.zshrc"
    else
        cp -a "$HOME/.zshrc" "$BACKUP_DIR/.zshrc"
    fi
fi

success "Backup created: $BACKUP_DIR"

# --------------------------------------------------
# Install dotfiles
# --------------------------------------------------

info "Installing dotfiles..."
cp -a "$REPO_DIR/.config/." "$CONFIG_DIR/"

if [[ -f "$REPO_DIR/.config/.zshrc" ]]; then
    cp "$REPO_DIR/.config/.zshrc" "$HOME/.zshrc"
fi

# Make bundled shell scripts executable.
find "$CONFIG_DIR" -type f -name "*.sh" -exec chmod +x {} \;

# Replace upstream/personal development home paths with the account currently
# running the installer, keeping the repository usable on another machine/user.
for cfg in \
    "$HOME/.config/wlogout/style.css" \
    "$HOME/.config/spicetify/config-xpui.ini"; do
    if [[ -f "$cfg" ]]; then
        sed -i \
            -e "s#/home/rp34#/home/$USER#g" \
            -e "s#/home/samuelm#/home/$USER#g" \
            "$cfg"
    fi
done

success "Dotfiles installed."

# --------------------------------------------------
# Papirus folder color
# --------------------------------------------------

if [[ -n "$AUR_HELPER" ]]; then
    info "Installing Papirus folders..."
    if "$AUR_HELPER" -S --needed --noconfirm papirus-folders \
        && command -v papirus-folders >/dev/null 2>&1 \
        && papirus-folders -C white; then
        success "Papirus folders set to white."
    else
        warning "Papirus folder setup failed; continuing."
    fi
else
    warning "No AUR helper available; skipping papirus-folders."
fi

# --------------------------------------------------
# Wallpapers
# --------------------------------------------------

if [[ -d "$REPO_DIR/Wallpapers" ]]; then
    info "Installing wallpapers..."
    mkdir -p "$HOME/Pictures/Wallpapers"
    cp -a "$REPO_DIR/Wallpapers/." "$HOME/Pictures/Wallpapers/"
    success "Wallpapers installed."
fi

# --------------------------------------------------
# User audio services
# --------------------------------------------------

if command -v systemctl >/dev/null 2>&1; then
    info "Enabling PipeWire user services..."
    if systemctl --user enable --now pipewire.service \
        && systemctl --user enable --now pipewire-pulse.service \
        && systemctl --user enable --now wireplumber.service; then
        success "PipeWire configured."
    else
        warning "One or more PipeWire user services could not be enabled."
    fi
fi

# --------------------------------------------------
# Finish
# --------------------------------------------------

printf '\n'
printf '\033[1;32m========================================\033[0m\n'
printf '\033[1;32m      Samuel Hyprland Setup Ready      \033[0m\n'
printf '\033[1;32m========================================\033[0m\n'
printf '\n'
printf 'Distribution:  %s\n' "${PRETTY_NAME:-unknown}"
printf 'AUR helper:    %s\n' "${AUR_HELPER:-none}"
printf 'Configuration: %s\n' "$CONFIG_DIR"
printf 'Backup:        %s\n' "$BACKUP_DIR"

if [[ "${#UNKNOWN_PACKAGES[@]}" -gt 0 ]]; then
    printf 'Unresolved:    %s\n' "${UNKNOWN_PACKAGES[*]}"
fi

printf '\n'
warning "Log out and back into Hyprland for all changes to take effect."
success "Installation complete."
