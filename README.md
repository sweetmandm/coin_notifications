## Dev

Prerequisites:
* virtualbox
* vagrant
* ansible

```bash
$ vagrant up

# manual step if the github repo is private:
# and a public github ssh key to vagrant's `/root/.ssh/authorized_keys`

$ ansible-playbook -i ansible/hosts ansible/provision.yml -l dev

$ ssh deployer@192.168.50.8
```
