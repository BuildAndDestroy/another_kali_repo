FROM kalilinux/kali-rolling:latest
RUN apt update -y
RUN apt upgrade -y
WORKDIR "/root/"
RUN apt install wget git -y
RUN apt install git live-build cdebootstrap debootstrap curl -y

# Clone Kali Live Build and configure
RUN git clone https://gitlab.com/kalilinux/build-scripts/live-build-config.git
WORKDIR "/root/live-build-config/"
RUN echo "# Additional Packages" >> kali-config/variant-default/package-lists/kali.list.chroot
RUN echo "gobuster" >> kali-config/variant-default/package-lists/kali.list.chroot
RUN echo "seclists" >> kali-config/variant-default/package-lists/kali.list.chroot
RUN echo "powershell-empire" >> kali-config/variant-default/package-lists/kali.list.chroot
RUN echo "starkiller" >> kali-config/variant-default/package-lists/kali.list.chroot
RUN echo "openssh-server" >> kali-config/variant-default/package-lists/kali.list.chroot
RUN echo "label install" >> kali-config/common/includes.binary/isolinux/install.cfg
RUN echo "    menu label ^Install Automated" >> kali-config/common/includes.binary/isolinux/install.cfg
RUN echo "    linux /install/vmlinuz" >> kali-config/common/includes.binary/isolinux/install.cfg
RUN echo "    initrd /install/initrd.gz --- quiet" >> kali-config/common/includes.binary/isolinux/install.cfg
RUN echo "    append vga=788 auto=true priority=critical locale=en_US keymap=us hostname=kali domain=kali" >> kali-config/common/includes.binary/isolinux/install.cfg
RUN rm kali-config/common/includes.installer/preseed.cfg
COPY preseed.cfg kali-config/common/includes.installer/
RUN mkdir /root/live-build-config/images/