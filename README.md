# nixos-config

NixOS configuration managed with Flakes.

## Hosts

| Hostname | Description |
|---|---|
| `vm001` | Virtual machine |
| `dccnlpt001` | Dell Precision 5560 laptop |

## Installing NixOS with Flake

The following steps walk through a fresh NixOS installation using `vm001` as an example.
The disk device is `/dev/vda`, the root filesystem is XFS, and the root partition is
protected with LUKS full-disk encryption.

### 1. Boot the NixOS installer

Download the NixOS minimal ISO from https://nixos.org/download and boot the VM from it, and enter the root-user shell with `sudo -i`.

### 2. Partition the disk

```bash
parted /dev/vda -- mklabel gpt
parted /dev/vda -- mkpart ESP fat32 1MB 512MB
parted /dev/vda -- set 1 esp on
parted /dev/vda -- mkpart primary 512MB 100%
```

This produces:

| Partition | Purpose |
|---|---|
| `/dev/vda1` | EFI system partition |
| `/dev/vda2` | LUKS-encrypted root |

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
```

The XFS filesystem is labeled `nixos` to match the device path used in
`hardware/generated/vm001.nix`.

### 5. Mount the filesystems

```bash
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/vda1 /mnt/boot
```

### 6. Generate hardware configuration

```bash
nixos-generate-config --root /mnt
```

### 7. Clone this repository

```bash
nix-shell -p git
git clone https://github.com/dccn-tg/nixos-config /mnt/etc/nixos/nixos-config
```

### 8. Copy the generated hardware configuration

Copy the generated file into the repository to overwrite `hardware/generated/vm001.nix`:

```bash
cp /mnt/etc/nixos/hardware-configuration.nix \
   /mnt/etc/nixos/nixos-config/hardware/generated/vm001.nix
```

### 9. Install NixOS

```bash
nixos-install --flake /mnt/etc/nixos/nixos-config#vm001
```

Set the root password when prompted; or

```bash
nixos-install --no-root-passwd --flake /mnt/etc/nixos/nixos-config#vm001 
```

to skip setting root password for unattended installation.

### 10. Set specific user password before reboot

For example, to set the password for user `honlee`:

```bash
nixos-enter --root /mnt -c 'passwd honlee'
```

### 11. Reboot

```bash
reboot
```

Remove the installer media. The boot loader will prompt for the LUKS passphrase
before mounting the root filesystem.

---

## Updating an existing system

After making changes to the configuration, rebuild and switch:

```bash
sudo nixos-rebuild switch --flake /etc/nixos/nixos-config#vm001
```

To upgrade to the latest packages pinned in the flake:

```bash
nix flake update /etc/nixos/nixos-config
sudo nixos-rebuild switch --flake /etc/nixos/nixos-config#vm001
```

---

## Adding a new host

1. Create a host file under `hosts/<hostname>.nix`.
2. Add the hardware configuration under `hardware/generated/<hostname>.nix`.
3. Register the host in `flake.nix`:

```nix
nixosConfigurations = {
  vm001       = mkHost ./hosts/vm001.nix;
  dccnlpt001  = mkHost ./hosts/dccnlpt001.nix;
  newhostname = mkHost ./hosts/newhostname.nix;  # add this line
};
```

4. Follow the installation steps above, substituting `vm001` with the new hostname.
