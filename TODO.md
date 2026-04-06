# TODO

## Deb10

setup role/deb10_custom_openssh
to handle custom compiled /opt/openssh for bins

## Devuan

### purged

apt purge x11-common fontconfig unbound shared-mime-info runit-helper iproute2 gcc-10-base

apt install dbus openssh-server

```text
fontconfig
The following packages were automatically installed and are no longer required:
    adwaita-icon-theme at-spi2-common at-spi2-core dconf-gsettings-backend
    dconf-service fonts-droid-fallback fonts-noto-mono gsettings-desktop-schemas
    gtk-update-icon-cache hicolor-icon-theme libaom3 libatk-bridge2.0-0 libatk1.0-0
    libatspi2.0-0 libavahi-client3 libavahi-common-data libavahi-common3
    libcairo-gobject2 libcairo2 libcolord2 libcups2 libdatrie1 libdav1d6 libdconf1
    libde265-0 libdeflate0 libepoxy0 libgdk-pixbuf-2.0-0 libgdk-pixbuf2.0-bin
    libgdk-pixbuf2.0-common libgif7 libgraphite2-3 libgs-common libgs10
    libgs10-common libgtk-3-common libharfbuzz0b libheif1 libhwy1 libice6 libid3tag0
    libijs-0.35 libjbig0 libjbig2dec0 libjpeg62-turbo libjxl0.7 liblcms2-2 liblerc4
    libnuma1 libopenjp2-7 libpaper-utils libpaper1 libpixman-1-0 libsm6 libspectre1
    libthai-data libthai0 libtiff6 libwayland-client0 libwayland-cursor0
    libwayland-egl1 libwebp7 libwebpdemux2 libx11-xcb1 libx265-199 libxcb-render0
    libxcb-shm0 libxcomposite1 libxcursor1 libxdamage1 libxfixes3 libxi6 libxinerama1
    libxkbcommon0 libxrandr2 libxt6 libxtst6 poppler-data xkb-data
Use 'apt autoremove' to remove them.
The following packages will be REMOVED:
    fontconfig*libgtk-3-0* libgtk-3-bin*libimlib2* libpango-1.0-0*
    libpangocairo-1.0-0* libpangoft2-1.0-0*librsvg2-2* librsvg2-common*
    policykit-1-gnome* w3m-img*

    2.1G -> 1.9G

apt purge x11-common
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following packages were automatically installed and are no longer required:
  fontconfig-config fonts-dejavu-core libfontconfig1 libfontenc1 libfreetype6 libtcl8.6
  libxft2 libxrender1
Use 'apt autoremove' to remove them.
The following packages will be REMOVED:
  blt* fonts-urw-base35* libtk8.6* libxss1* python3-tk* tk8.6-blt2.5* x11-common*
  xfonts-encodings* xfonts-utils*
0 upgraded, 0 newly installed, 9 to remove and 2 not upgraded.
After this operation, 22.5 MB disk space will be freed.

apt purge unbound
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following packages were automatically installed and are no longer required:
  dns-root-data libevent-2.1-7 libprotobuf-c1 libpython3.11
Use 'sudo apt autoremove' to remove them.
The following packages will be REMOVED:
  unbound*
0 upgraded, 0 newly installed, 1 to remove and 2 not upgraded.
After this operation, 5,513 kB disk space will be freed.

apt purge shared-mime-info
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following packages will be REMOVED:
  shared-mime-info*
0 upgraded, 0 newly installed, 1 to remove and 2 not upgraded.
After this operation, 5,149 kB disk space will be freed.

apt purge runit-helper
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following packages were automatically installed and are no longer required:
  dbus dbus-bin dbus-daemon dbus-session-bus-common dbus-system-bus-common dbus-x11
  elogind libapparmor1 libdbus-1-3 libduktape207 libelogind-compat libelogind0
  libpam-elogind libpolkit-agent-1-0 libpolkit-gobject-1-0
  libpolkit-gobject-elogind-1-0 libwrap0 openssh-sftp-server pkexec policykit-1 polkitd
  polkitd-pkla sgml-base ucf xml-core
Use 'sudo apt autoremove' to remove them.
The following packages will be REMOVED:
  openssh-server* runit-helper*
0 upgraded, 0 newly installed, 2 to remove and 2 not upgraded.
After this operation, 1,970 kB disk space will be freed.

 apt purge iproute2
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following packages were automatically installed and are no longer required:
  dbus dbus-bin dbus-daemon dbus-session-bus-common dbus-system-bus-common dbus-x11
  elogind libapparmor1 libbpf1 libdbus-1-3 libduktape207 libelogind-compat libelogind0
  libpam-elogind libpolkit-agent-1-0 libpolkit-gobject-1-0
  libpolkit-gobject-elogind-1-0 libwrap0 openssh-sftp-server pkexec policykit-1
  polkitd polkitd-pkla sgml-base ucf
  xml-core
Use 'sudo apt autoremove' to remove them.
The following packages will be REMOVED:
  iproute2* isc-dhcp-client*
0 upgraded, 0 newly installed, 2 to remove and 2 not upgraded.
After this operation, 7,346 kB disk space will be freed.

apt install dbus

 apt purge gcc-10-base
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following packages will be REMOVED:
  gcc-10-base*
0 upgraded, 0 newly installed, 1 to remove and 2 not upgraded.
After this operation, 267 kB disk space will be freed.

```

## remove ish-aok references

Since this fork is no longer maintained, no more suppprt for this fork needed

## commits

## performance

repo deployed & remote_src: true - 13m 11s
remote_src: false - 33m 45s (when stuff was updated) - 33m 41s (repeat run - no changes)

- copy:
- template:

## mtr Alpine repos

Sample url `https://dl-cdn.alpinelinux.org/alpine/v3.22/main/x86/`

### in main/x86

- Alpine 3.10 - mtr-0.92-r0 From: 2019-05-08
- Alpine 3.11 - mtr-0.93-r2

### in community/x86/

- Alpine 3.12 - mtr-0.93-r2
- Alpine 3.13 - mtr-0.94-r1
- Alpine 3.14 - same
- Alpine 3.15 - same
- Alpine 3.16 - mtr-0.95-r1
- Alpine 3.17 - same
- Alpine 3.18 - mtr-0.95-r2
- Alpine 3.22 - same

## Deploy Times on iPad 7th

- Alpine 3.19 - 37:46
- Alpine 3.22 - 39:41- Alpine 3.22 - 39:41
