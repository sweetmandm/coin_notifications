## Coin Notifications

This application listens for transaction events from `bitcoind`, tracks confirmations, and sends out SMS messages for bitcoin addresses that you're interested in.

It's a working proof-of-concept, but for more reliable 0-transaction notifications (and more timely notifications), it would likely need to connect to several globaly distributed full bitcoin nodes.

Though the PoC sends out SMS, it could just as easily (and more usefully) connect to some other service and allow that service to determine where to send the notification.

- Parses raw transactions and blocks from `bitcoind`
- Extracts addresses from the standard transaction scripts
- Keeps the best 30 blocks and sends SMS messages on requested confirmation counts.

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

Try out a notification:

1. cd `coin_notifications`
2. manually add twilio creds to coinpusher/config/notifier_config.exs (this will be automated in the future)
3. `iex -S mix`
4. To get notifications for confirmations 0, 2, and 5 (note address uses single-quotes):
`iex(1)> CoinPusher.NotificationsController.add_listener('<address>', "<phone>", [0, 2, 5])`
5. `$ btccli generate 101 # to free up the first coinbase tx`
6. `$ btccli sendtoaddress <address> 1.0`
7. You should see the first 0-confirmation notification go out.
8. When subsequent blocks are generated you should see confirmations 2 and 5 go out.


When you're ssh'd into a box provisioned by the included Ansible roles, you will also have a command `btccli` which will execute against the active bitcoin network and data directory, so you don't have to use `bitcoin-cli -regtest -rpcuser= ... -datadir=...`

For example:

```bash
$ btccli getinfo
{
  "version": 140300,
  "protocolversion": 70015,
  ...
}
```

