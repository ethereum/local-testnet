#!/usr/bin/env bash

source ./scripts/util.sh
set -eu

mkdir -p $ROOT
mkdir -p $BUILD_DIR

if ! test -e ./web3/node_modules; then
    echo "The package ./web3 doesn't have node modules installed yet. Installing the node modules now"
    npm --prefix ./web3 install >/dev/null 2>/dev/null
    echo "Node modules are already installed"
fi

# Use the signing node as a node to deploy the deposit contract
output=$(npm --prefix ./web3 exec deploy-deposit-contract -- --endpoint $SIGNER_EL_DATADIR/geth.ipc)
address=$(echo "$output" | grep "address" | cut -d ' ' -f 2)
transaction=$(echo "$output" | grep "transaction" | cut -d ' ' -f 2)
block_number=$(echo "$output" | grep "block_number" | cut -d ' ' -f 2)

echo "Deployed the deposit contract of the address $address in the transaction $transaction on the block number $block_number"

echo $address > $ROOT/deposit-address

if ! test -e $BUILD_DIR/deposit; then
    echo "$BUILD_DIR/deposit not found. Downloading it from https://github.com/ethereum/staking-deposit-cli"

    curl -s -L -o $ROOT/deposit.tar.gz "https://github.com/ethereum/staking-deposit-cli/releases/download/v2.3.0/staking_deposit-cli-76ed782-linux-amd64.tar.gz"
    tar xf $ROOT/deposit.tar.gz -C $ROOT

    mv $ROOT/staking_deposit-cli-76ed782-linux-amd64/deposit $BUILD_DIR/deposit
    rm -rf $ROOT/staking_deposit-cli-76ed782-linux-amd64 $ROOT/deposit.tar.gz

    echo "$BUILD_DIR/deposit downloaded"
fi

validator_count=0
if test -e $BUILD_DIR/validator_keys; then
    # Check how many validators we have already generated
    validator_count=$(find $BUILD_DIR/validator_keys -name "keystore*" -print | wc -l)
fi

if test $validator_count -lt $VALIDATOR_COUNT; then
    echo "Generating the credentials for all of $VALIDATOR_COUNT validators at $BUILD_DIR/validator_keys"

    # Generate only for the remaining validators
    # We use kiln because we have the same GENESIS_FORK_VERSION which is 0x70000069
    $BUILD_DIR/deposit \
        --language english \
        --non_interactive \
        existing-mnemonic \
        --num_validators $(expr $VALIDATOR_COUNT - $validator_count)\
        --mnemonic="abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about" \
        --validator_start_index $validator_count \
        --chain kiln \
        --keystore_password $(cat $ROOT/password) \
        --folder $BUILD_DIR

    echo "Done generating the credentials"
fi

# Select the validator
npm --prefix ./web3 exec select-validators -- \
    -c $VALIDATOR_COUNT \
    -f $(find $BUILD_DIR/validator_keys -name "deposit_data*.json") \
    > $ROOT/deposit-data.json

echo "Sending the deposits to the deposit contract"
npm --prefix ./web3 exec transfer-deposit -- \
    --endpoint $SIGNER_EL_DATADIR/geth.ipc \
    --deposit-address $address \
    -f $ROOT/deposit-data.json
echo -e "\nDone sending all the deposits to the contract"
