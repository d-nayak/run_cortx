#!/bin/bash

set -x

sudo mkdir -p /var/motr
for i in {0..9}; do
    sudo dd if=/dev/zero of=/var/motr/disk$i.img bs=1M seek=9999 count=1
    sudo losetup /dev/loop$i /var/motr/disk$i.img
done
