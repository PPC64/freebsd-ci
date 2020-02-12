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
-M pseries,cap-cfpc=broken,cap-sbbc=broken,cap-ibs=broken,cap-htm=off \
-m {} \
-drive file=meta.tar,if=virtio,index=1,format=raw \
-drive file={},if=virtio,index=0,format=raw \
-nographic -vga none \
-netdev user,id=ppcnet0 -device virtio-net-pci,netdev=ppcnet0\
".format(TEST_VM_NAME, VM_CPU_COUNT, VM_MEM_SIZE, IMG_NAME)

print(cmd)

child = pexpect.spawn(cmd, timeout=86400)
child.logfile = sys.stdout
child.delaybeforesend = 0.5

prompt = " #"

child.expect(re.compile("^login:", re.MULTILINE))
forsend(child, "root")
child.expect(prompt)

forsend(child, "env ASSUME_ALWAYS_YES=yes pkg update")
child.expect(prompt)

forsend(child, "pkg install -y kyua")
child.expect(prompt)

forsend(child, "cd /usr/tests")
child.expect(prompt)

forsend(child, "/usr/local/bin/kyua test")
child.expect(prompt)

forsend(child, "/usr/local/bin/kyua report --verbose --results-filter passed,skipped,xfail,broken,failed --output test-report.txt")
child.expect(prompt)

forsend(child, "/usr/local/bin/kyua report-junit --output=test-report.xml")
child.expect(prompt)

forsend(child, "ifconfig")
child.expect(prompt)

forsend(child, "date")
child.expect(prompt)

forsend(child, "shutdown -p now")

#wait up to 8 hours
child.expect("Uptime:.*")
