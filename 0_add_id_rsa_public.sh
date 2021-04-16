#!/bin/bash

id_rsa_public="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAxYepQiOrFXyRsAy5tLmzhIw+Wpgssh5YUZ+zDq5GKpySVrlSGYOJEqFI3JOSYImW+TGUCRnZQNBipYdULd7an4fNDPBx4ZwPXotVrQwwWEkf8p6NPCnGVHqj+cwOYdgm6Oj8LP3W9djqA+6ojkpIk6h+KBp0D4rKVR1mmpBYrQ9Ty0dd7nH1qxwdUYSVV2xT1pc8/70r2OVjSAstEhItzFvNFGIl5X9e5VIgtZyKplWub4+R6bMBKY+M/ZAmzqLw5jAWVJv2Iu2YFeQgv105fFbBAobvkvxy8VdMFCalbl5UqTXMEjg+ZDH4eiGtR2mk7TsDdF7aIU6OIbSOoaTAqQ== rsa 2048-022219"

[ -d ~/.ssh ] || { mkdir -p ~/.ssh; chmod 700 ~/.ssh; }
[ -f ~/.ssh/authorized_keys ] || { touch ~/.ssh/authorized_keys; chmod 600 ~/.ssh/authorized_keys; }

grep -q "$id_rsa_public" ~/.ssh/authorized_keys || \
	echo "$id_rsa_public" >> ~/.ssh/authorized_keys

