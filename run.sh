#!/usr/bin/env bash

source ./scripts/util.sh
set -u +e

if ! test $(uname -s) = "Linux"; then
    echo "Only Linux is supported"
fi

check_cmd() {
    if ! command -v $1 >/dev/null; then
        echo -e "\nCommand '$1' not found, please install it first.\n\n$2\n"
        exit 1
    fi
}

if test -e $ROOT; then
    echo "The file $ROOT already exists, please delete or move it first."
    exit 1
fi

check_cmd geth "See https://geth.ethereum.org/docs/getting-started/installing-geth for more detail."
check_cmd bootnode "See https://geth.ethereum.org/docs/getting-started/installing-geth for more detail."
check_cmd lighthouse "See https://lighthouse-book.sigmaprime.io/installation.html for more detail."
check_cmd lcli "See https://lighthouse-book.sigmaprime.io/installation-source.html and run \"make install-lcli\"."
check_cmd npm "See https://nodejs.org/en/download/ for more detail."
check_cmd node "See https://nodejs.org/en/download/ for more detail."

cleanup() {
    echo "Shutting down"
    pids=$(jobs -p)
    while ps p $pids >/dev/null 2>/dev/null; do
        kill $pids 2>/dev/null
        sleep 1
    done
    while test -e $ROOT; do
        rm -rf $ROOT 2>/dev/null
        sleep 1
    done
    echo "Deleted the data directory"
}

trap cleanup EXIT

mkdir -p $ROOT

# Run everything needed to generate $BUILD_DIR
if ! ./scripts/build.sh; then
    echo -e "\n*Failed!* in the build step\n"
    exit 1
fi

if ! ./scripts/prepare-el.sh; then
    echo -e "\n*Failed!* in the execution layer preparation step\n"
    exit 1
fi
./scripts/el-bootnode.sh &
bootnode_pid=$!

# Keep reading until we can parse the boot enode
while true; do
    if ! ps p $bootnode_pid >/dev/null; then
        exit 1
    fi
    boot_enode="$(cat $EL_BOOT_LOG_FILE 2>/dev/null | grep -o "enode:.*$" || true)"
    if ! test -z "$boot_enode"; then
        break
    fi
    sleep 1
done

for (( node=1; node<=$NODE_COUNT; node++ )); do
    ./scripts/el-node.sh $node $boot_enode &
done

./scripts/signer-node.sh $SIGNER_EL_DATADIR $boot_enode &

# Wait until the signer node starts the IPC socket
while ! test -S $SIGNER_EL_DATADIR/geth.ipc; do
    sleep 1
done

if ! ./scripts/prepare-cl.sh; then
    echo -e "\n*Failed!* in the consensus layer preparation step\n"
    exit 1
fi
./scripts/cl-bootnode.sh &

for (( node=1; node<=$NODE_COUNT; node++ )); do
    ./scripts/cl-bn-node.sh $node &
    ./scripts/cl-vc-node.sh $node &
done

wait -n
