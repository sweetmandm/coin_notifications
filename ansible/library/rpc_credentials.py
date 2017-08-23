#!/usr/bin/python
# -*- coding: utf-8 -*-

from ansible.module_utils.basic import AnsibleModule
import hashlib
import sys
import os
from random import SystemRandom
import base64
import hmac

def main():
    module = AnsibleModule(
        argument_spec = dict(
            dest = dict(default='./.rpc_auth.yml', type='str'),
            force = dict(default=False, type='bool'),
        ),
        supports_check_mode=True
    )

    force = module.params["force"]
    dest = module.params["dest"]

    if module.check_mode:
        module.exit_json(changed=should_generate(force, dest))
    elif should_generate(force, dest):
        generate_new_credentials(dest)
        module.exit_json(changed=True, file=dest)
    else:
        module.exit_json(changed=False, file=dest)


def should_generate(force, dest):
    return force or not os.path.isfile(dest)


def generate_new_credentials(dest):
    cryptogen = SystemRandom()

    #Create 32 byte b64 password and username
    username = base64.urlsafe_b64encode(os.urandom(32))
    password = base64.urlsafe_b64encode(os.urandom(32))

    #Create 16 byte hex salt
    salt_sequence = [cryptogen.randrange(256) for i in range(16)]
    hexseq = list(map(hex, salt_sequence))
    salt = "".join([x[2:] for x in hexseq])

    digestmod = hashlib.sha256

    if sys.version_info.major >= 3:
        password = password.decode('utf-8')
        digestmod = 'SHA256'

    m = hmac.new(bytearray(salt, 'utf-8'), bytearray(password, 'utf-8'), digestmod)
    result = m.hexdigest()
    
    rpcauth = username+":"+salt+"$"+result

    write_file(dest, username, password, rpcauth)


def write_file(dest, username, password, rpcauth):
    authfile = open(dest, "w")
    text = auth_vars_text(username, password, rpcauth)
    authfile.write(text)
    authfile.close()


def auth_vars_text(username, password, rpcauth):
    return """
---
rpc:
  username: %s
  password: %s
  auth: %s
""" % (username, password, rpcauth)


if __name__ == '__main__':
    main()
