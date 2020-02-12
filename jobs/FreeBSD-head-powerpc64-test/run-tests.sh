#!/bin/sh

SSL_CA_CERT_FILE=/usr/local/share/certs/ca-root-nss.crt

if [ -z "${SVN_REVISION}" ]; then
	echo "No subversion revision specified"
	exit 1
fi

ARTIFACT_SERVER=${ARTIFACT_SERVER:-https://artifact.ci.freebsd.org}
ARTIFACT_SUBDIR=snapshot/${FBSD_BRANCH}/r${SVN_REVISION}/${TARGET}/${TARGET_ARCH}
IMG_NAME=disk-test.img
JOB_DIR=freebsd-ci/jobs/${JOB_NAME}
TEST_BASE=`dirname $0`

TIMEOUT_MS=${BUILD_TIMEOUT:-5400000}
TIMEOUT=$((${TIMEOUT_MS} / 1000))
TIMEOUT_EXPECT=$((${TIMEOUT} - 60))
TIMEOUT_VM=$((${TIMEOUT_EXPECT} - 120))

VM_CPU_COUNT=4
VM_MEM_SIZE=4096m

EXTRA_DISK_NUM=5
BHYVE_EXTRA_DISK_PARAM=""

METADIR=meta
METAOUTDIR=meta-out

#fetch ${ARTIFACT_SERVER}/${ARTIFACT_SUBDIR}/${IMG_NAME}.xz
wget http://10.10.71.21:8180/jenkins/job/FreeBSD-head-powerpc64-testvm/ws/artifact/head/r357757/powerpc/powerpc64/disk-test.img.xz -o ./disk-test.img.xz

xz -fd ${IMG_NAME}.xz

for i in `jot ${EXTRA_DISK_NUM}`; do
	truncate -s 128m disk${i}
	BHYVE_EXTRA_DISK_PARAM="${BHYVE_EXTRA_DISK_PARAM} -s $((i + 3)):0,ahci-hd,disk${i}"
done

# prepare meta disk to pass information to testvm
rm -fr ${METADIR}
mkdir ${METADIR}
cp -R ${JOB_DIR}/${METADIR}/ ${METADIR}/
for i in ${USE_TEST_SUBR}; do
	cp ${TEST_BASE}/subr/${i} ${METADIR}/
done
touch ${METADIR}/auto-shutdown
sh -ex ${TEST_BASE}/create-meta.sh

# run test VM image with qemu
FBSD_BRANCH_SHORT=`echo ${FBSD_BRANCH} | sed -e 's,.*-,,'`
TEST_VM_NAME="testvm-${FBSD_BRANCH_SHORT}-${TARGET_ARCH}-${BUILD_NUMBER}"

export IMG_NAME=${IMG_NAME}
export VM_CPU_COUNT=${VM_CPU_COUNT}
export VM_MEM_SIZE=${VM_MEM_SIZE}
export TEST_VM_NAME=${TEST_VM_NAME}
python -u ${JOB_BASE}/test-in-qemu.py

echo "qemu return code = $rc"

# extract test result
sh -ex ${TEST_BASE}/extract-meta.sh
rm -f test-report.*
mv ${METAOUTDIR}/test-report.* .

for i in `jot ${EXTRA_DISK_NUM}`; do
	rm -f disk${i}
done
rm -f ${IMG_NAME}
