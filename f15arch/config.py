#!/usr/bin/env python3

# For a new system, boot the arch install media, and run
# pacman -Sy git
# git clone https://github.com/ProgrammierPatrick/dotfiles.git /srv/dotfiles
# /srv/dotfiles/f15arch/config.py

import subprocess as sp
from pathlib import Path
import re

USERNAME = "patrick"
HOSTNAME = "f15arch"
PACKAGES = [
    "base",
    "base-devel",
    "python",
    "git",
    "linux",
    "linux-firmware",
    "intel-ucode",
    "nvidia-open", # DRM driver
    "nvidia-utils", # nvidia-smi, blacklists nouveau, OpenGL, Vulkan, DDX
    "lib32-nvidia-utils", # 32bit OpenGL, Vulkan
    "nvidia-prime", # prime-run, shortcut script to set prime env vars. Actually oneliner
    "drm-info", # small utility to read out drm devices
    "mesa", # intel iGPU OpenGL
    "vulkan-intel", # intel iGPU Vulkan
    "terminus-font", # getty font ter-124b
    "cuda",
    "grub", # GRUB itself
    "efibootmgr", # writes to EFI. Used by grub-install
    "os-prober", # auto detect other OSs on grub-mkconfig
    "grub-btrfs",
    "btrfs-progs",
    "networkmanager",
    "wpa_supplicant",
    "vim",
    "nano",
    "htop",
    "mission-center",
    "gparted",
    "man-db",
    "man-pages",
    "texinfo",
    "sudo",
    "pipewire",
    "pipewire-alsa",
    "pipewire-pulse",
    "pipewire-jack",
    "wireplumber",
    "qpwgraph",
    "gnome",
    "gnome-browser-connector",
    "power-profiles-daemon",
    "bash-completion",
    "flatpak",
    "firefox",
    "chromium",
    "libreoffice-fresh",
    "blender",
    "keepass",
    "gimp",
    "code",
    "steam",
    "lutris",
    "wine-mono",
    "wine-gecko",
    "gamescope",
]

FLATPACKS = [
    "com.discordapp.Discord",
    "com.spotify.Client",
    "com.vysp3r.ProtonPlus",
    "com.github.tchx84.Flatseal",
]

def main():
    hostname = read_file("/etc/hostname").strip()
    if hostname == "archiso":
        arch_install()
    else:
        config()

def config():
    pacman_conf = read_file("/etc/pacman.conf")
    # if multilib commented out "#[multilib], #Include = ..."
    if re.search(r"^\s*#\s*\[multilib\]", pacman_conf, re.MULTILINE):
        print("Enabling multilib repo in /etc/pacman.conf")
        # Remove # from both [multilib] and its Include line
        pacman_conf = re.sub(
            r"^(\s*)#(\s*\[multilib\]\s*\n\s*)#(\s*Include\s*=\s*[^\n]+)",
            r"\1\2\3",
            pacman_conf,
            flags=re.MULTILINE
        )
        write_file("/etc/pacman.conf", pacman_conf)

    run_cmd(["pacman", "-Syu", "--needed", *PACKAGES], check=True)

    for flatpack in FLATPACKS:
        run_cmd(["flatpak", "install", "-y", "flathub", flatpack], check=True)

    # Gnome set keyboard layout
    run_cmd(["sudo", "-Hu", "patrick", "dbus-launch", "gsettings", "set", "org.gnome.desktop.input-sources", "sources", "[('xkb', 'de')]"], check=True)

    # Setup nvidia only wayland gnome sessison for gdm greeter
    print("Creating NVIDIA-only GNOME session for GDM...")
    write_file("/usr/share/wayland-sessions/custom-gnome-nvidia.desktop",
        "[Desktop Entry]\n"
        "Name=GNOME (NVIDIA)\n"
        "Comment=Run GNOME Desktop using NVIDIA GPU\n"
        "Exec=env __NV_PRIME_RENDER_OFFLOAD=1 __VK_LAYER_NV_optimus=NVIDIA_only __GLX_VENDOR_LIBRARY_NAME=nvidia /usr/bin/gnome-session --session=gnome\n"
        "DesktopNames=GNOME\n"
        "Type=Application\n")

    # Link EDID Monitor HDR data directory to system firmware settings
    run_cmd(["sudo", "ln", "-sfv", "/srv/dotfiles/edid", "/usr/lib/firmware/edid"], check=True)

    # TODO: noch in GRUB eintragen
    # GRUB konfigurieren: Editiere /etc/default/grub und füge den folgenden Parameter zur Zeile GRUB_CMDLINE_LINUX_DEFAULT hinzu:
    # drm.edid_firmware=DEIN_DOCK_ANSCHLUSS:edid/lg_27gs95qe.bin
    # Achte darauf, dass du den Parameter an das Ende der Zeile anfügst und er durch ein Leerzeichen vom Rest getrennt ist.
    # GRUB aktualisieren:
    # sudo grub-mkconfig -o /boot/grub/grub.cfg

def arch_install():
    getty_keymap = "de-latin1"
    getty_font = "ter-124b"
    locale = "en_US.UTF-8 UTF-8"

    print("We are doing a fresh arch install!")
    run_cmd(["loadkeys", getty_keymap], check=True)
    run_cmd(["setfont", getty_font], check=True)
    print()
    print("Check we are booted into 64bit EFI mode..")
    if read_file("/sys/firmware/efi/fw_platform_size").strip() != "64":
        exit("We are not booted in 64bit EFI mode!")
    print()
    print("Check internet connection")
    if run_cmd(["ping", "-c1", "1.1.1.1"]).returncode != 0:
        exit("Ensure internet connection, and run this script again.")
    print()
    run_cmd(["lsblk"], check=True)
    print("Please format the disk for installation.")
    print("Ensure, that it is formatted as follows:")
    print("1: EFI System Partition, Mounted as /mnt/boot/efi")
    print("2..N-1: Windows stuff, Mounted as /mnt/win, /mnt/win2")
    print("N: \"Arch Boot Partition\" 1GB ext4, Mounted as /mnt/boot")
    print("N+1: \"Arch Linux\" btrfs, Mounted as /mnt")
    print("use fdisk /dev/xxx to partition")
    print("use mkfs.ext4 to format boot partition")
    print("use mkfs.btrfs to format arch partition")
    print("use mount --mkdir to mount partitions.")
    print("Mount Flags: compress=zstd for btrfs")
    print("Perform partition, formatting, and mounting, then exit the Shell by Ctrl+D.")
    print("")
    run_cmd("bash", shell=True, check=True)
    print("")
    print("Check mounted partitions")
    mount = read_cmd("mount | grep \"/mnt\"", show_all=True)
    if "on /mnt type btrfs" not in mount: exit("mount /mnt missing or wrong")
    if "on /mnt/boot type ext4" not in mount: exit("mount /mnt/boot missing or wrong")
    if "on /mnt/boot/efi type vfat" not in mount: exit("mount /mnt/boot/efi missing or wrong")

    run_cmd([
        "pacstrap",
        "-K", 
        "/mnt",
        *PACKAGES
    ], check=True)
    print()
    if "/boot/efi" not in read_file("/mnt/etc/fstab", require_exists=False):
        run_cmd("genfstab /mnt >> /mnt/etc/fstab", shell=True, check=True)
    read_file("/mnt/etc/fstab", show_all=True)
    print("")
    run_cmd(["arch-chroot", "/mnt", "ln", "-sf", "/usr/share/zoneinfo/Europe/Berlin", "/etc/localtime"], check=True)
    run_cmd(["arch-chroot", "/mnt", "hwclock", "--systohc"])
    run_cmd(["arch-chroot", "/mnt", "timedatectl", "set-local-rtc", "1"]) # Use Windows-compatible local time
    print("")
    run_cmd(f"echo '{locale}' >> /mnt/etc/locale.gen", shell=True, check=True)
    run_cmd(["arch-chroot", "/mnt", "locale-gen"], check=True)
    print("")
    write_file("/mnt/etc/vconsole.conf", f"KEMAP={getty_keymap}\nFONT={getty_font}\n")
    print("")
    write_file("/mnt/etc/hostname", HOSTNAME)
    print("")
    write_file("/mnt/etc/grub.d/40_custom", "GRUB_SAVEDEFAULT=true\nGRUB_DISABLE_OS_PROBER=false\n")
    run_cmd(["arch-chroot", "/mnt", "os-prober"], check=True)
    run_cmd(["arch-chroot", "/mnt", "grub-install", "--target=x86_64-efi", "--efi-directory=/boot/efi", "--bootloader-id=GRUB"], check=True)
    run_cmd(["arch-chroot", "/mnt", "grub-mkconfig", "-o", "/boot/grub/grub.cfg"], check=True)
    print("")
    run_cmd(["arch-chroot", "/mnt", "systemctl", "enable", "NetworkManager"], check=True)
    run_cmd(["arch-chroot", "/mnt", "timedatectl", "set-ntp", "true"], check=True)
    print("")
    run_cmd(["arch-chroot", "/mnt", "useradd", "-mG", "wheel", USERNAME], check=True)
    run_cmd("arch-chroot /mnt visudo", check=True, shell=True)
    run_cmd(["arch-chroot", "/mnt", "passwd", USERNAME], check=True)
    print("")
    print("Setup complete. Now reboot into your new system.")

def read_file(path: str, require_exists=True, **kwargs) -> str:
    p = Path(path)
    if not p.exists():
        if not require_exists: return ""
        exit(f"Error: file {path} could not be read. Does not exist.")
    content = p.read_text()
    log_result(f"read {path}", content, **kwargs)
    return content

def write_file(path: str, text: str, **kwargs):
    p = Path(path)
    p.write_text(text)
    log_result(f"written {path}", text, **kwargs)

def read_cmd(cmd: str, **kwargs) -> str:
    result = sp.run(cmd, shell=True, text=True, capture_output=True)
    if result.returncode != 0:
        exit(f"Error: command {cmd} retured {result.returncode}.")
    log_result(f"run {cmd}", result.stdout, **kwargs)
    return result.stdout

def log_result(action: str, result: str, show_all=False):
    lines = result.splitlines()
    if len(lines) == 1: print(f"* {action} -> {lines[0]}")
    else:
        print(f"* {action} -> {len(lines)} lines")
        for l in lines if show_all else lines[0:8]:
            print(f"  | {l}")

def run_cmd(*args, **kvargs):
    print(f"* {"".join(args) if kvargs.get("shell", False) else " ".join(*args)} {kvargs}")
    return sp.run(*args, **kvargs)

if __name__ == "__main__":
    main()

