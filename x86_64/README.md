# Kali unattended installer ISO (x86_64)

This builds a custom Kali Linux ISO for 64-bit Intel/AMD machines. It includes:

* An **"Install Automated (preseed)"** boot menu entry that installs Kali with no questions asked.
* Extra Kali packages from [`daily_use.txt`](daily_use.txt) (or [`minimal_use.txt`](minimal_use.txt) for the minimal variant).
* Extra tools from GitHub or Go, listed in [`tools.yaml`](tools.yaml), installed into `/opt` and added to your `PATH`.

Everything runs inside Docker, so the only thing your machine needs is Docker.

> [!WARNING]
> **The automated install erases the target machine's disk without asking.** Test it in a virtual machine first, and never boot the ISO on a machine whose data you want to keep, then pick "Install Automated".

---

## 1. What you need

| Requirement | Notes |
| --- | --- |
| A Linux host | Kali, Ubuntu, or Debian are known to work. It must be x86_64. |
| Docker | Ubuntu/Debian: `sudo apt install docker.io`. Kali: `sudo apt install docker.io`. |
| Disk space | Plan for **at least 50 GB free**. The build downloads and unpacks a full Kali system. |
| Internet access | Packages and tools are downloaded during the build. |
| Time | Usually **1 to 3 hours**, depending on your connection and CPU. |
| `mkpasswd` | Used to hash your password. Ubuntu/Debian: `sudo apt install whois`. Kali has it already. |

Check that Docker works before you continue:

```bash
sudo docker run --rm hello-world
```

## 2. Get the code

```bash
git clone https://github.com/BuildAndDestroy/another_kali_repo.git
cd another_kali_repo
```

Run every command below from this `another_kali_repo` folder (the repo root, **not** `x86_64/`).

## 3. Create your password hash

The installer creates a user called **`kali`**. You choose its password by giving the build a hashed copy of it. Your real password is never stored in the repo.

```bash
mkpasswd -m sha-512
```

Type your password when asked. You get a line starting with `$6$`, for example:

```
$6$Abc123...$LongStringOfCharacters...
```

Copy the whole line. If you don't have `mkpasswd`, this gives the same kind of hash:

```bash
openssl passwd -6
```

## 4. Build the builder image

Paste your hash between the **single quotes**. The single quotes matter, because the hash contains `$` characters that your shell would otherwise change.

```bash
sudo docker build \
  -t kali-unattended-builder:1 \
  --build-arg USER_PASSWORD_HASH='PASTE_YOUR_HASH_HERE' \
  -f x86_64/everything.dockerfile .
```

This step takes a few minutes. It prepares the build environment; it does **not** make the ISO yet.

If you see `[-] Pass --build-arg USER_PASSWORD_HASH=...` or `must be a SHA-512 crypt hash`, the hash is missing or wasn't copied correctly. Go back to step 3.

> [!NOTE]
> Docker records build arguments in the image history (`docker history`). The image only contains the *hash*, not your password, but still **don't push this image** to Docker Hub or any other registry.

## 5. Build the ISO

Make a folder for the finished ISO, then run the build:

```bash
mkdir -p images

sudo docker run --rm -it --privileged -e DEBUG=1 \
  -v "$(pwd)/images:/opt/live-build-config/images" \
  kali-unattended-builder:1 \
  ./build.sh --variant default --output images
```

`--privileged` is required, because building an ISO needs to mount filesystems.

When it finishes, the ISO is in the `images/` folder:

```bash
ls -lh images/
```

### Choosing a variant

The `--variant` option picks the desktop and package set.

| Variant | What you get |
| --- | --- |
| `default` | Xfce desktop, Kali's default tools, plus everything in `daily_use.txt`. **Start here.** |
| `xfce` | Same as `default` (upstream `default` points to `xfce`). |
| `minimal` | A small system with only the packages in `minimal_use.txt`. |

Kali also has other variants (`gnome`, `kde`, `large`, `everything`, ...). Those work too, but they do **not** include the packages from `daily_use.txt`. The tools from `tools.yaml` are added to every variant.

## 6. Install Kali from the ISO

1. **Try it in a VM first** (VirtualBox, VMware, or QEMU/virt-manager). Give the VM a single disk of at least 40 GB and an internet connection.

   > [!IMPORTANT]
   > Set the VM's disk controller to **SATA**, not VirtIO. The preseed installs the boot loader to `/dev/sda`. A VirtIO disk shows up as `/dev/vda`, so the automated install won't find the disk it expects. In virt-manager: *Add Hardware / disk → Bus type: SATA*. In QEMU: `-drive file=disk.qcow2,if=none,id=d0 -device ahci,id=ahci -device ide-hd,drive=d0,bus=ahci.0`.

2. To use real hardware, write the ISO to a USB stick with [balenaEtcher](https://etcher.balena.io/) or `dd`:

   ```bash
   # Replace /dev/sdX with your USB stick. Double check it - this erases the stick.
   sudo dd if=images/<your-iso-name>.iso of=/dev/sdX bs=4M status=progress conv=fsync
   ```

3. Boot from the ISO. In the boot menu, choose **Install Automated (preseed)** (shortcut: press `a`). It works in both BIOS and UEFI mode.
4. Wait. The installer partitions the disk, installs Kali and reboots on its own.
5. Log in as user **`kali`** with the password you hashed in step 3.

The other boot menu entries (Live system, the normal installers) still work as usual.

### What the automated install sets up

These come from [`preseed.cfg`](preseed.cfg). Edit that file and rebuild (steps 4 and 5) to change them.

| Setting | Value | Line in `preseed.cfg` |
| --- | --- | --- |
| Language / keyboard | `en_US` / `us` | `debian-installer/locale`, `keyboard-configuration/xkb-keymap` |
| Time zone | `US/Mountain` | `time/zone` |
| Hostname | `kali` | `netcfg/get_hostname` |
| User | `kali` (root login disabled) | `passwd/username` |
| Disk layout | Whole disk, one partition (`atomic`) | `partman-auto/choose_recipe` |
| Boot loader disk | `/dev/sda` | `grub-installer/bootdev` |

> [!IMPORTANT]
> The boot loader is installed to **`/dev/sda`**. If your machine's disk has another name, such as `/dev/nvme0n1` (NVMe SSDs) or `/dev/vda` (some VMs), change `grub-installer/bootdev` to match, or the installed system may not boot. If the machine has more than one disk, the installer may stop and ask which one to use.

The time zone list is in `/usr/share/zoneinfo/` on any Linux machine (for example `America/New_York` or `Europe/London`).

## 7. Customizing

After any change, rebuild with steps 4 and 5.

### Add Kali packages

Add one package name per line to:

* [`daily_use.txt`](daily_use.txt) for the `default` / `xfce` variant
* [`minimal_use.txt`](minimal_use.txt) for the `minimal` variant

Names must match Kali packages exactly. Search at <https://pkg.kali.org/> or with `apt search <name>` on Kali.

### Add tools from GitHub or Go

Add an entry to [`tools.yaml`](tools.yaml). During the build, [`generate-install-hooks.sh`](generate-install-hooks.sh) turns each entry into an install script. Most tools end up in `/opt/<name>` with a `<name>` command in your `PATH`.

```yaml
tools:
  - name: jwt_tool                                   # command name and /opt folder
    type: git+python                                 # how to install it (see below)
    repo: https://github.com/ticarpi/jwt_tool.git
    bin: jwt_tool.py                                 # script to run, relative to the repo
    venv: true                                       # install in its own Python venv
```

| `type` | Fields | What it does |
| --- | --- | --- |
| `git+python` | `repo`, `bin`, `venv`, `pyversion` | Clones the repo and installs Python dependencies. With `venv: true` it uses a private virtualenv (recommended). Uses `requirements.txt` if the repo has one, otherwise `pip install .`. Add `pyversion: "3.11"` for tools that don't work on Kali's newer Python; Python 3.11 is then built from source (this adds build time). |
| `git+pipenv` | `repo`, `bin`, `venv` | Same idea, using `pipenv`. |
| `go` | `go_path` | Runs `go install <go_path>@latest`. For modules at v2 or later, include the suffix, e.g. `github.com/hahwul/dalfox/v2`. |
| `make+go` | `repo`, `bin`, `outname`, `wordlist` | Clones and runs `make build`, then installs `bin` as the command `outname`. `wordlist: true` is specific to kiterunner. |
| `git` / `git+bash` | `repo`, optional `bin` | Just clones to `/opt/<name>`. With `bin`, links that file into your `PATH`. |
| `rust` | (none) | Runs `cargo install <name>`. |

A tool whose install fails will stop the whole ISO build, so test new entries before you rely on them.

## Troubleshooting

| Problem | Fix |
| --- | --- |
| `permission denied ... docker.sock` | Put `sudo` in front of the docker commands, or add yourself to the `docker` group and log in again. |
| Build stops with `[-] Pass --build-arg USER_PASSWORD_HASH` | The hash wasn't passed. See steps 3 and 4. |
| Build stops with `install_start.cfg anchor not found` | Kali changed their boot menu layout upstream. Open an issue so the menu entry can be updated. |
| ISO build fails during a `99-<tool>.hook.chroot` step | That tool from `tools.yaml` failed to install (the repo moved, or its dependencies changed). Comment it out with `#` and rebuild. |
| No space left on device | Free up disk space; see the requirements in step 1. Docker's leftovers can be removed with `sudo docker system prune`. |
| Installed system won't boot | Check `grub-installer/bootdev` in `preseed.cfg` matches your disk (see step 6). |
| Automated install fails or asks about the disk in a VM | The VM disk is probably on VirtIO (`/dev/vda`). Switch the disk bus to **SATA** (see step 6). |
| The installer asks questions | Something isn't covered by `preseed.cfg` on your hardware (often the disk choice when there are several disks). Answer it, or add the answer to `preseed.cfg`. |

## Files in this folder

| File | Purpose |
| --- | --- |
| `everything.dockerfile` | Builds the builder image used in step 4. |
| `preseed.cfg` | Answers for the automated installer. |
| `grub-automated-install.cfg` | The "Install Automated (preseed)" boot menu entry. |
| `daily_use.txt` / `minimal_use.txt` | Extra Kali packages. |
| `tools.yaml` | Extra tools from GitHub/Go. |
| `generate-install-hooks.sh` | Turns `tools.yaml` into install scripts. |
| `python-installer-hooks/` | Builds Python 3.11 for tools that need it. |
| `debian-docker.dockerfile` | **Deprecated.** Old Debian-based builder; kept for reference only. |
