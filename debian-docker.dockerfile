FROM debian:buster
RUN apt update -y
RUN apt upgrade -y
WORKDIR "/root/"
RUN apt install wget git -y
RUN apt install git live-build cdebootstrap debootstrap curl -y

# Install required packages
RUN wget http://http.kali.org/pool/main/k/kali-archive-keyring/kali-archive-keyring_2020.2_all.deb
RUN wget https://archive.kali.org/kali/pool/main/l/live-build/live-build_20210216_all.deb

# Prep for Kali packaging
RUN dpkg -i kali-archive-keyring_2020.2_all.deb
RUN dpkg -i live-build_20210216_all.deb
WORKDIR "/usr/share/debootstrap/scripts/"
RUN echo "default_mirror http://http.kali.org/kali"; sed -e "s/debian-archive-keyring.gpg/kali-archive-keyring.gpg/g" sid > /tmp/kali
RUN mv /tmp/kali .
WORKDIR "/root/"

# Clone Kali Live Build and configure
RUN git clone https://gitlab.com/kalilinux/build-scripts/live-build-config.git
WORKDIR "/root/live-build-config/"
RUN echo "# Additional Packages" >> kali-config/variant-default/package-lists/kali.list.chroot
RUN echo "gobuster" >> kali-config/variant-default/package-lists/kali.list.chroot
RUN echo "seclists" >> kali-config/variant-default/package-lists/kali.list.chroot
RUN echo "powershell-empire" >> kali-config/variant-default/package-lists/kali.list.chroot
RUN echo "starkiller" >> kali-config/variant-default/package-lists/kali.list.chroot
RUN echo "openssh-server" >> kali-config/variant-default/package-lists/kali.list.chroot

# Add an Automated Install in Grub
RUN echo "label install" >> kali-config/common/includes.binary/isolinux/install.cfg
RUN echo "    menu label ^Install Automated" >> kali-config/common/includes.binary/isolinux/install.cfg
RUN echo "    linux /install/vmlinuz" >> kali-config/common/includes.binary/isolinux/install.cfg
RUN echo "    initrd /install/initrd.gz --- quiet" >> kali-config/common/includes.binary/isolinux/install.cfg
RUN echo "    append vga=788 auto=true priority=critical locale=en_US keymap=us hostname=kali domain=kali" >> kali-config/common/includes.binary/isolinux/install.cfg
RUN rm kali-config/common/includes.installer/preseed.cfg
COPY preseed.cfg kali-config/common/includes.installer/
RUN mkdir /root/live-build-config/images/
