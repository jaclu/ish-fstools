# iSH FS tools

Creates and maintains a more complete Linux like CLI env on iSH

- Adding some iSH focused extra tools in /usr/local/bin and /usr/local/sbin
- Custom /etc/inittab and app launcher, aimed at handling some of the iSH quirks
- Pleny of room for user config, like what apps to install and so on
- Deploying via ansible

## Preparaiton

### iSH node

Only relevant if deploying via ansible to the iSH node, if the FS is prepared in a
chroot, then the resulting FS can be deployed directly.

#### Install a minirootfs on iSH

- Download a recent image, something like
`https://dl-cdn.alpinelinux.org/alpine/v3.22/releases/x86/alpine-minirootfs-3.22.1-x86.tar.gz`
- Copy it to the iOS device via iCloud or similar if downloaded on other device
- In the iSH app `Settings - Filesystems - import` then select the minirootfs,
  finally select `Boot From This Filesystem`

#### Configure the new FS to run sshd

Follow the procedure on this page: `https://github.com/ish-app/ish/wiki/Running-an-SSH-server`

### Deploy node

Deploy initial configurations via templates

```shell
cp conf_templates/inventory.ini .
mkdir vars
cp conf_templates/overrides.yml vars/
```

#### Configuration

##### inventory.ini

If remote deploy is used, add a line for each iSH node that should be updated under
the section `[servers]` there is one name based and one IP# based example that
can be used as templates

For chrooted deploys, there is no need to configure this file

##### Deploy config

Edit `vars/overrides.yml`

## Deploy

### Remote deploy via deploy host

- run the deploy `./handle_servers.sh`

### chroot deploy

```shell

wget https://dl-cdn.alpinelinux.org/alpine/v3.22/releases/x86/alpine-minirootfs-3.22.1-x86.tar.gz

# Unpack it
mkdir chroot-FS
cd  chroot-FS
tar ../xfz alpine-minirootfs-3.22.1-x86.tar.gz
cd ..

# Copy this repo into the chroot env
cp -av ../ish-fstools chroot-FS chroot-FS/opt
```

#### Run deploy inside chroot

`/opt/ish-fstools/handle_localhost.sh`

## mtr (My traceroute)

Recent versions of mtr, post 0.92 can only resolve dns names on iSH. Due to this
an older version, 0.92-a from Alpine 3.10 is installed. This can also handle
hosts given with IP#, thus supporting hostnames listed in /etc/hosts
