## Coin Notifications

This application listens for transaction events from `bitcoind` and sends out notifications when a transaction happens on a bitcoin address that you're interested in.

It has the ability to parse raw transactions and extract addresses from transaction scripts in order to minimize RPC calls to the bitcoin daemon.

## Dev

`bitcoind` only includes ZeroMQ support in the linux version, so if you're on macOS you need to set up a VM to run it.

This project includes an Vagrantfile and Ansible roles to provision it. Just follow these steps:

Prerequisites:
* virtualbox
* vagrant
* ansible

```bash
$ vagrant up
$ ssh-add .vagrant/machines/default/virtualbox/private_key
$ ansible-playbook -i ansible/hosts ansible/provision.yml -l dev
$ vagrant ssh
```

After you've ssh'd into the box, Ansible has also provided a command-line command `btccli` which will execute against the active bitcoin network and data directory, so you don't have to use `bitcoin-cli -regtest -datadir=...`

For example:

```bash
$ btccli getinfo
{
  "version": 140300,
  "protocolversion": 70015,
  ...
}
```

Try out a notification:

1. manually add twilio creds to coinpusher/config/notifier_config.exs (this will be automated in the future)
2. iex -S mix
3. To get notifications for confirmations 0, 2, and 5 (note address uses single-quotes):
`iex(1)> CoinPusher.NotificationsController.add_listener('<address>', "<phone>", [0, 2, 5])`
4. `$ btccli generate 101 # to free up the first coinbase tx`
4. `$ btccli sendtoaddress <address> 1.0`
5. You should see the first notification go out.
6. When subsequent blocks are generated you should see confirmations 2 and 5 go out.
