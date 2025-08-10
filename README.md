# ansible fs deploy

Be aware, this is still in early development, so can't actually be used yet...

```shell
apk update && apk upgrade && apk add ansible

ansible-playbook provisioning.yml
```

## mtr (My traceroute)

Recent versions of mtr, pos 0.92 can only resolv dns names on iSH. Due to this
an older version, 0.92-a from Alpine 3.10 is installed. This can also handle
hosts given with IP#, thus supporting hostnames listed in /etc/hosts
