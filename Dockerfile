FROM kalilinux/kali-rolling:latest
RUN apt update -y
RUN apt upgrade -y
WORKDIR "/root/"
RUN apt install wget git -y
RUN apt install git live-build cdebootstrap debootstrap curl simple-cdd -y

# Clone Kali Live Build and configure
RUN git clone https://gitlab.com/kalilinux/build-scripts/live-build-config.git
WORKDIR "/root/live-build-config/"
COPY daily_use.txt ./
RUN cat daily_use.txt >> kali-config/variant-default/package-lists/kali.list.chroot
RUN mkdir kali-config/variant-minimal/package-lists
RUN touch kali-config/variant-minimal/package-lists/kali.list.chroot
COPY minimal_use.txt ./
RUN cat minimal_use.txt >> kali-config/variant-minimal/package-lists/kali.list.chroot

# Add an Automated Install in Grub
RUN echo "label install" >> kali-config/common/includes.binary/isolinux/install.cfg
RUN echo "    menu label ^Install Automated" >> kali-config/common/includes.binary/isolinux/install.cfg
RUN echo "    linux /install/vmlinuz" >> kali-config/common/includes.binary/isolinux/install.cfg
RUN echo "    initrd /install/initrd.gz --- quiet" >> kali-config/common/includes.binary/isolinux/install.cfg
RUN echo "    append vga=788 auto=true priority=critical locale=en_US keymap=us hostname=kali domain=kali" >> kali-config/common/includes.binary/isolinux/install.cfg
RUN rm kali-config/common/includes.installer/preseed.cfg
COPY preseed.cfg kali-config/common/includes.installer/
RUN mkdir /root/live-build-config/images/
