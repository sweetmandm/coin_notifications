## Coin Notifications

The goal of this project is to send SMS/email/iOS push notifications when a transaction happens on a bitcoin wallet that you're interested in.

It's a WIP, but the Ansible roles are configured to provision a server, start up bitcoind with options configurable by environment, and make sure it stays running.

## Dev

`bitcoind` only includes ZeroMQ support in the linux version, so if you're on macOS you need to set up a VM to run it.

This project includes an Vagrantfile and Ansible roles to provision it. Just follow these steps:

Prerequisites:
* virtualbox
* vagrant
* ansible

```bash
$ vagrant up

# Manual step:
# - And a public ssh key to vagrant's `/root/.ssh/authorized_keys`
# - `ssh-add` the private key on your host machine

$ ansible-playbook -i ansible/hosts ansible/provision.yml -l dev

$ ssh deployer@192.168.50.8
```

After you've ssh'd into the box, Ansible has also provided a command-line command `btccli` which will execute against the active bitcoin network and data directory, so you don't have to use `bitcoin-cli -testnet -datadir=...`

For example:

```bash
$ btccli getinfo
{
  "version": 140300,
  "protocolversion": 70015,
  ...
}
```
