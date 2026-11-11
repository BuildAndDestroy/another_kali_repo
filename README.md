# another_kali_repo

Build your own Kali Linux ISO with an **automated, hands-off installer** and your favourite extra tools already installed.

Everything is built inside Docker, so all you need is a Linux machine with Docker.

## Quick start (x86_64)

```bash
git clone https://github.com/BuildAndDestroy/another_kali_repo.git
cd another_kali_repo

# 1. Hash the password for the "kali" user
mkpasswd -m sha-512          # or: openssl passwd -6

# 2. Build the builder image (keep the single quotes around the hash)
sudo docker build -t kali-unattended-builder:1 \
  --build-arg USER_PASSWORD_HASH='PASTE_YOUR_HASH_HERE' \
  -f x86_64/everything.dockerfile .

# 3. Build the ISO (takes 1 to 3 hours); it ends up in ./images/
mkdir -p images
sudo docker run --rm -it --privileged -e DEBUG=1 \
  -v "$(pwd)/images:/opt/live-build-config/images" \
  kali-unattended-builder:1 ./build.sh --variant default --output images
```

Then boot the ISO and choose **Install Automated (preseed)**.

> [!WARNING]
> The automated install **erases the target disk without asking**. Try it in a virtual machine first.

> [!IMPORTANT]
> When testing in a VM, set the disk to **SATA**, not VirtIO. The installer expects `/dev/sda`.

**For the full step-by-step guide, customization, and troubleshooting, see [x86_64/README.md](x86_64/README.md).**

## Layout

| Folder | Status |
| --- | --- |
| [`x86_64/`](x86_64/) | 64-bit Intel/AMD builds. Working. |
| ARM | Not supported yet. ARM needs a different build process and will get its own folder. |

## Resources

* https://gitlab.com/kalilinux/recipes/kali-preseed-examples
* https://www.kali.org/docs/development/live-build-a-custom-kali-iso/
* https://www.kali.org/docs/development/dojo-mastering-live-build/
