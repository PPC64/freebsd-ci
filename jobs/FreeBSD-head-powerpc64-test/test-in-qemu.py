#!/usr/local/bin/python

import re
import sys
import os

import pexpect

IMG_NAME = os.environ['IMG_NAME']
VM_CPU_COUNT = os.environ['VM_CPU_COUNT']
VM_MEM_SIZE = os.environ['VM_MEM_SIZE']
TEST_VM_NAME = os.environ['TEST_VM_NAME']


def forsend(child, s):
    for c in s:
        child.send(c)
    child.sendline()

cmd = "qemu-system-ppc64 \
-name {} \
-smp {} \
-M pseries,cap-cfpc=broken,cap-sbbc=broken,cap-ibs=broken,cap-hpt-max-page-size=16M \
-m {} \
-drive file=meta.tar,format=raw,if=virtio
-drive file={},if=virtio,index=0,format=raw \
-nographic -vga none \
-netdev user,id=mynet0 -device spapr-vlan,netdev=mynet0\
".format(TEST_VM_NAME, VM_CPU_COUNT, VM_MEM_SIZE, IMG_NAME)

print(cmd)

child = pexpect.spawn(cmd)
child.logfile = sys.stdout
child.delaybeforesend = 0.5

child.expect(re.compile("^login:", re.MULTILINE), timeout=600)
forsend(child, "root")

child.expect("#", timeout=300)
forsend(child, "shutdown -p now")

#wait up to 8 hours
child.expect("Uptime:.*", timeout=28800)
