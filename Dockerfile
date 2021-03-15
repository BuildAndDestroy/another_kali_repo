FROM kalilinux/kali-rolling:latest
RUN apt update -y
RUN apt upgrade -y
WORKDIR "/root/"
RUN apt install wget git -y
RUN apt install git live-build cdebootstrap debootstrap curl -y
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
RUN echo "    append vga=788 preseed/url=http://YOURHTTPIPADDRESS/preseed.cfg auto=true priority=critical locale=en_US keymap=us hostname=kali domain=kali" >> kali-config/common/includes.binary/isolinux/install.cfg
RUN mkdir /root/live-build-config/kali-config/common/debian-installer
COPY preseed.cfg kali-config/common/debian-installer/preseed.cfg
RUN mkdir /root/live-build-config/images/
