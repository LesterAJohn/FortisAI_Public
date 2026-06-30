#!/usr/bin/env bash
set -e

echo "=== Podman Storage Driver Migration: VFS → overlay ==="

USER_HOME="/opt/home/aiuser"
STORAGE_CONF="$USER_HOME/.config/containers/storage.conf"
GRAPHROOT="$USER_HOME/.local/share/containers/storage"
RUNROOT="/run/user/1001/containers"

echo "Using storage.conf: $STORAGE_CONF"
# ---------------------------------------------------------
# 3. Reset Podman storage
# ---------------------------------------------------------
echo "Resetting Podman storage (this removes old VFS layers)..."
podman system reset

# ---------------------------------------------------------
# 1. Ensure fuse-overlayfs is installed
# ---------------------------------------------------------
if ! command -v fuse-overlayfs >/dev/null 2>&1; then
    echo "Installing fuse-overlayfs..."
    sudo dnf install -y fuse-overlayfs || sudo apt install -y fuse-overlayfs
else
    echo "fuse-overlayfs already installed."
fi

# ---------------------------------------------------------
# 2. Update storage.conf
# ---------------------------------------------------------
echo "Updating storage.conf..."

mkdir -p "$(dirname "$STORAGE_CONF")"

cat > "$STORAGE_CONF" <<EOF
[storage]
driver = "overlay"
graphroot = "$GRAPHROOT"
runroot = "$RUNROOT"

[storage.options]
mount_program = "/usr/bin/fuse-overlayfs"
EOF

echo "storage.conf updated:"
cat "$STORAGE_CONF"

# ---------------------------------------------------------
# 4. Recreate storage directories
# ---------------------------------------------------------
mkdir -p "$GRAPHROOT"
mkdir -p "$RUNROOT"

echo "Storage directories prepared."

echo "=== Migration Complete ==="
echo "Podman is now using overlay + fuse-overlayfs."
