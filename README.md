# nixos-config

NixOS configuration managed with Flakes.

## Installing NixOS with Flake

The [`scripts/install.sh`](scripts/install.sh) script performs a fully unattended NixOS installation from this flake. It handles every step below automatically.

**Prerequisites:**

1. Enter system firmware and set Secure Boot to **Setup Mode**.
2. Boot from the NixOS minimal ISO.
3. Enter a root shell: `sudo -i`

**Run the script:**

```bash
# If running from a fresh ISO (repo not yet cloned):
git clone https://github.com/dccn-tg/nixos-config
sudo bash nixos-config/scripts/install.sh <hostname> <disk-device>
```

Examples:

```bash
sudo bash scripts/install.sh vm001 /dev/vda
sudo bash scripts/install.sh dccnlpt001 /dev/nvme0n1
```

The script will:
- Prompt for a LUKS passphrase and `nixadmin` user password (once, at the start).
- Ask for confirmation before wiping the disk.
- Partition, encrypt, format, and mount the disk.
- Clone this repository into `/mnt/etc/nixos/nixos-config` (if not already present).
- Generate and copy the hardware configuration.
- Install NixOS and set the `nixadmin` password.

---

The following steps walk through what the script does, using `vm001` and `/dev/vda` as examples. The root partition is XFS, protected with LUKS full-disk encryption, and a swap partition sized at **1.2× physical RAM** is created automatically.

### 1. Boot the NixOS installer

Download the NixOS minimal ISO from https://nixos.org/download, boot from it, and enter the root-user shell:

```bash
sudo -i
```

### 2. Partition the disk

The swap size is calculated as 1.2× the total physical RAM (in GB). Substitute `${swapGB}` with that value for your machine.

```bash
parted /dev/vda -- mklabel gpt
parted /dev/vda -- mkpart ESP fat32 1MB 512MB
parted /dev/vda -- set 1 esp on
parted /dev/vda -- mkpart primary 512MB -${swapGB}GB
parted /dev/vda -- mkpart swap linux-swap -${swapGB}GB 100%
```

This produces:

| Partition | Purpose |
|---|---|
| `/dev/vda1` | EFI system partition (512 MB) |
| `/dev/vda2` | LUKS-encrypted root (XFS) |
| `/dev/vda3` | Swap (1.2× physical RAM) |

### 3. Set up LUKS encryption on the root partition

```bash
cryptsetup luksFormat /dev/vda2
cryptsetup open /dev/vda2 cryptroot
```

The decrypted device will be available at `/dev/mapper/cryptroot`.

### 4. Format the partitions

```bash
mkfs.fat -F 32 -n boot /dev/vda1
mkfs.xfs -L nixos /dev/mapper/cryptroot
mkswap -L swap /dev/vda3
swapon /dev/vda3
```

The XFS filesystem is labeled `nixos` to match the device path used in `hardware/generated/vm001.nix`.

### 5. Mount the filesystems

```bash
udevadm settle
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/vda1 /mnt/boot
```

### 6. Generate hardware configuration

```bash
nixos-generate-config --root /mnt
```

### 7. Clone this repository

If the script is run from within an already-cloned copy of this repository, this step is skipped automatically. Otherwise, the repo is cloned into `/mnt/etc/nixos/nixos-config`:

```bash
git clone https://github.com/dccn-tg/nixos-config /mnt/etc/nixos/nixos-config
```

### 8. Create the host-specific configuration

If `hosts/<hostname>.nix` does not yet exist, it is generated from the template:

```bash
sed s/@@HOSTNAME@@/vm001/g \
    /mnt/etc/nixos/nixos-config/hosts/host.template \
    > /mnt/etc/nixos/nixos-config/hosts/vm001.nix
git -C /mnt/etc/nixos/nixos-config add hosts/vm001.nix
```

### 9. Copy the generated hardware configuration

Copy the generated file into the repository:

```bash
cp /mnt/etc/nixos/hardware-configuration.nix \
   /mnt/etc/nixos/nixos-config/hardware/generated/vm001.nix
git -C /mnt/etc/nixos/nixos-config add hardware/generated/vm001.nix
```

### 10. Install NixOS

```bash
nixos-install --no-root-passwd --flake /mnt/etc/nixos/nixos-config#vm001
```

### 11. Set the nixadmin user password

```bash
nixos-enter --root /mnt -c 'passwd nixadmin'
```

### 12. Reboot

```bash
reboot
```

Remove the installer media. The boot loader will prompt for the LUKS passphrase before mounting the root filesystem. After logging in as `nixadmin`, change your password immediately:

```bash
passwd
```

---

## Updating an existing system

Use [`scripts/rebuild.sh`](scripts/rebuild.sh) to rebuild the current host:

```bash
sudo bash scripts/rebuild.sh
```

The script auto-detects the hostname, ensures `hosts/<hostname>.nix` exists (generating it from the template if not), copies the current `/etc/nixos/hardware-configuration.nix` into the repo as `hardware/generated/<hostname>.nix`, and runs `nixos-rebuild switch`.

To upgrade to the latest packages pinned in the flake before rebuilding:

```bash
nix flake update /etc/nixos/nixos-config
sudo bash scripts/rebuild.sh
```

### Adding a new module

1. Add the new `.nix` file under `modules/`.
2. Add its import to `hosts/host.template`.
3. Remove the previously generated host config and hardware config for each affected host. Since these files were staged with `git add` by the script, use `git rm` to remove them from both disk and the index:

   ```bash
   git rm hosts/<hostname>.nix
   git rm hardware/generated/<hostname>.nix
   ```

4. Run `rebuild.sh` — the script will regenerate both files from the updated template and current hardware config, then rebuild:

   ```bash
   sudo bash scripts/rebuild.sh
   ```
