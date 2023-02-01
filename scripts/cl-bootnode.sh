#!/usr/bin/env bash

source ./scripts/util.sh
set -u +e

cleanup() {
    kill $(jobs -p) 2>/dev/null
}

trap cleanup EXIT

# Start the boot node
echo "Started the lighthouse bootnode which is now listening at port $CL_BOOTNODE_PORT"

# --disable-packet-filter is necessary because it's involed in rate limiting and nodes per IP limit
# See https://github.com/sigp/discv5/blob/v0.1.0/src/socket/filter/mod.rs#L149-L186
$LIGHTHOUSE_CMD boot_node \
    --testnet-dir $CONSENSUS_DIR \
    --port $CL_BOOTNODE_PORT \
    --listen-address 127.0.0.1 \
	--disable-packet-filter \
    --network-dir $CL_BOOTNODE_DIR \
    < /dev/null > $CL_BOOT_LOG_FILE 2>&1

if test $? -ne 0; then
    node_error "The CL bootnode returns an error. The last 10 lines of the log file is shown below.\n\n$(tail -n 10 $CL_BOOT_LOG_FILE)"
    exit 1
fi
