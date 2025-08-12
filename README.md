# iSH FS Tools

Provides a more complete Linux-like CLI environment on iSH by:

- Adding iSH-specific utilities to `/usr/local/bin` and `/usr/local/sbin`  
- Supplying a custom `/etc/inittab` and application launcher to address iSH quirks  
- Allowing extensive user configuration (e.g., which apps to install)  
- Supporting deployment via Ansible  

## Preparation

### iSH Node Setup

This step is required only if deploying directly to the iSH device via Ansible.  
If you prepare the filesystem in a chroot environment, you can deploy that filesystem d
irectly.

#### Installing a Minirootfs on iSH

1. Download a recent Alpine minirootfs image, for example:
```sh
https://dl-cdn.alpinelinux.org/alpine/v3.22/releases/x86/alpine-minirootfs-3.22.1-x86.tar.gz
```
2. Transfer the image to the iOS device (via iCloud or similar if downloaded elsewhere).
3. In the iSH app, go to `Settings → Filesystems → Import`, select the minirootfs,
then choose `Boot From This Filesystem`.

#### Configuring SSH Server on the New Filesystem

Follow instructions here:  
`https://github.com/ish-app/ish/wiki/Running-an-SSH-server`

### Deploy Node Setup

Deploy initial configurations using templates:

```sh
cp conf_templates/inventory.ini .
mkdir vars
cp conf_templates/overrides.yml vars/
```

## Configuration Files

- `inventory.ini` If deploying remotely, add each iSH node under the [servers] section.
Example entries by name and IP address are included as templates.
For chroot-based deployment, this file is not required.
- `vars/overrides.yml` Edit this file to customize deployment parameters.

## Deployment

### Remote Deployment via Deploy Host

Run the deployment script:

```sh
./handle_servers.sh
```

### Chroot Deployment

Download and unpack the Alpine minirootfs:

```sh
wget https://dl-cdn.alpinelinux.org/alpine/v3.22/releases/x86/alpine-minirootfs-3.22.1-x86.tar.gz

mkdir chroot-FS
cd chroot-FS
tar xfz ../alpine-minirootfs-3.22.1-x86.tar.gz
cd ..
```

Copy this repository into the chroot environment:

```sh
cp -av ish-fstools chroot-FS/opt
```

#### Running Deployment Inside the Chroot

Execute:

```sh
/opt/ish-fstools/handle_localhost.sh
```

## Notes on `mtr` (My traceroute)

Recent versions of `mtr` (post 0.92) cannot resolve DNS names on iSH.
This repository installs an older version (0.92-a from Alpine 3.10) that supports
hostname resolution via `/etc/hosts` and IP addresses directly.
