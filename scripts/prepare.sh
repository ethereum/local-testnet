#!/usr/bin/env bash

source ./scripts/util.sh
set -eu

mkdir $ROOT

# Generate a dummy password for accounts
echo "none" > $ROOT/password

genesis=$(cat $GENESIS_TEMPLATE_FILE)
for (( node=1; node<=$NODE_COUNT; node++ )); do
    el_data_dir $node
    datadir=$el_data_dir

    # Generate a new account for each geth node
    address=$(geth --datadir $datadir account new --password $ROOT/password 2>/dev/null | grep -o "0x[0-9a-fA-F]*")
    echo "Generated an account with address $address for geth node #$node and saved it at $datadir"
    echo $address > $datadir/address

    # Add the account into the genesis state
    alloc=$(echo $genesis | jq ".alloc + { \"${address:2}\": { \"balance\": \"300000\" } }")
    genesis=$(echo $genesis | jq ". + { \"alloc\": $alloc }")
done

# Generate the genesis state
echo $genesis > $GENESIS_FILE
echo "Generated $GENESIS_FILE"

# Initialize the geth nodes' directories
for (( node=1; node<=$NODE_COUNT; node++ )); do
    el_data_dir $node
    datadir=$el_data_dir

    geth init --datadir $datadir $GENESIS_FILE 2>/dev/null
    echo "Initialized the data directory $datadir with $GENESIS_FILE"
done

# Generate the boot node key
bootnode -genkey $BOOT_KEY_FILE
echo "Generated $BOOT_KEY_FILE"
