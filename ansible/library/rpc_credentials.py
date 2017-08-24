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

    write_file(dest, username, password)


def write_file(dest, username, password):
    authfile = open(dest, "w")
    text = auth_vars_text(username, password)
    authfile.write(text)
    authfile.close()


def auth_vars_text(username, password):
    return """
---
rpc_username: %s
rpc_password: %s
""" % (username, password)


if __name__ == '__main__':
    main()
