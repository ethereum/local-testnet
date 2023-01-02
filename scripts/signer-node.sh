#!/usr/bin/env bash

source ./scripts/util.sh
set -u +e

cleanup() {
    kill $(jobs -p) 2>/dev/null
}

trap cleanup EXIT

datadir=$1
boot_enode=$2

address=$(cat $datadir/address)
port=3011
rpc_port=3012
log_file=$datadir/geth.log

echo "Started the geth node 'signer' which is now listening at port $port"
geth \
    --datadir $datadir \
    --authrpc.port $rpc_port \
    --port $port \
    --bootnodes $boot_enode \
    --networkid $NETWORK_ID \
    --unlock $address \
    --password $ROOT/password \
    --mine \
    > $log_file 2>&1

if test $? -ne 0; then
    node_error "The geth node 'signer' returns an error. Please look at $log_file more detail."
    exit 1
fi
