#!/usr/bin/env bash

source ./scripts/util.sh
set -u +e

check_cmd() {
    if ! command -v $1 >/dev/null; then
        echo -e "\nCommand '$1' not found, please install it first.\n\nSee $2 for more detail.\n"
        exit 1
    fi
}

if test -e $ROOT; then
    echo "The file $ROOT already exists, please delete or move it first."
    exit 1
fi

check_cmd geth "https://geth.ethereum.org/docs/getting-started/installing-geth"
check_cmd bootnode "https://geth.ethereum.org/docs/getting-started/installing-geth"

cleanup() {
    echo "Shutting down"
    pids=$(jobs -p)
    kill $pids 2>/dev/null
    while ps p $pids >/dev/null 2>/dev/null; do
        sleep 1
    done
    while test -e $ROOT; do
        rm -rf $ROOT
        sleep 1
    done
    echo "Deleted the data directory"
}

trap cleanup EXIT

if ! ./scripts/prepare.sh; then
    echo -e "\n*Failed!* in the preparation step\n"
    exit 1
fi
./scripts/bootnode.sh &
bootnode_pid=$!

# Keep reading until we can parse the boot enode
while true; do
    if ! ps p $bootnode_pid >/dev/null; then
        exit 1
    fi
    boot_enode="$(cat $BOOT_LOG_FILE 2>/dev/null | grep -o "enode:.*$" || true)"
    if ! test -z "$boot_enode"; then
        break
    fi
    sleep 1
done

for (( node=1; node<=$NODE_COUNT; node++ )); do
    ./scripts/el-node.sh $node $boot_enode &
done

wait -n
