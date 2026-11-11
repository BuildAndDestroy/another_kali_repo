FROM kalilinux/kali-rolling:latest
RUN apt update -y
RUN apt upgrade -y
WORKDIR "/opt/"
RUN apt install wget git -y
RUN apt install git live-build cdebootstrap debootstrap curl simple-cdd golang yq -y

# Install dependencies and rustup
RUN apt update && \
    apt install -y curl build-essential pkg-config libssl-dev && \
    curl https://sh.rustup.rs -sSf | sh -s -- -y

# Add Rust to PATH
ENV PATH="/root/.cargo/bin:${PATH}"

# Clone Kali Live Build and configure
RUN git clone https://gitlab.com/kalilinux/build-scripts/live-build-config.git
WORKDIR "/opt/live-build-config/"
COPY x86_64/daily_use.txt ./
COPY x86_64/generate-install-hooks.sh kali-config/common/hooks/
COPY x86_64/tools.yaml kali-config/common/hooks/
COPY x86_64/python-installer-hooks kali-config/common/hooks/live/
RUN chmod 755 kali-config/common/hooks/generate-install-hooks.sh
RUN ./kali-config/common/hooks/generate-install-hooks.sh
RUN cat daily_use.txt >> kali-config/variant-default/package-lists/kali.list.chroot
RUN mkdir kali-config/variant-minimal/package-lists
RUN touch kali-config/variant-minimal/package-lists/kali.list.chroot
COPY x86_64/minimal_use.txt ./
RUN cat minimal_use.txt >> kali-config/variant-minimal/package-lists/kali.list.chroot

# Add an Automated Install entry to the GRUB menu (used for both BIOS and UEFI).
# Inserted right after the installer block opens in upstream grub.cfg; fail the
# build loudly if upstream changes that anchor.
COPY x86_64/grub-automated-install.cfg /tmp/
RUN GRUB_CFG=kali-config/common/bootloaders/grub-pc/grub.cfg && \
    grep -q 'source  */boot/grub/install_start.cfg' "$GRUB_CFG" || \
      { echo "[-] install_start.cfg anchor not found in $GRUB_CFG - upstream layout changed"; exit 1; } && \
    sed -i '\|source  */boot/grub/install_start.cfg|r /tmp/grub-automated-install.cfg' "$GRUB_CFG" && \
    grep -q 'Install Automated' "$GRUB_CFG"

# Preseed with the user password hash injected from a build arg.
# Generate with: mkpasswd -m sha-512
ARG USER_PASSWORD_HASH
RUN rm kali-config/common/includes.installer/preseed.cfg
COPY x86_64/preseed.cfg kali-config/common/includes.installer/
RUN test -n "$USER_PASSWORD_HASH" || \
      { echo "[-] Pass --build-arg USER_PASSWORD_HASH='<output of mkpasswd -m sha-512>'"; exit 1; } && \
    case "$USER_PASSWORD_HASH" in \$6\$*) ;; *) echo "[-] USER_PASSWORD_HASH must be a SHA-512 crypt hash (\$6\$...)"; exit 1;; esac && \
    sed -i "s|@USER_PASSWORD_HASH@|${USER_PASSWORD_HASH}|g" kali-config/common/includes.installer/preseed.cfg && \
    ! grep -q '@USER_PASSWORD_HASH@' kali-config/common/includes.installer/preseed.cfg
RUN mkdir /opt/live-build-config/images/
