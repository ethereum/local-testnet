#!/usr/bin/env bash

source ./scripts/util.sh
set -u +e

cleanup() {
    kill $(jobs -p) 2>/dev/null
}

trap cleanup EXIT

index=$1

cl_data_dir $index
datadir=$cl_data_dir
log_file=$datadir/validator_client.log

echo "Started the lighthouse validator client #$index. You can see the log at $log_file"

# Send all the fee to the PoA signer
$LIGHTHOUSE_CMD validator_client \
    --datadir $datadir \
	--testnet-dir $CONSENSUS_DIR \
	--init-slashing-protection \
    --beacon-nodes http://localhost:$(expr $BASE_CL_HTTP_PORT + $index) \
    --suggested-fee-recipient $(cat $SIGNER_EL_DATADIR/address) \
    < /dev/null > $log_file 2>&1

if test $? -ne 0; then
    node_error "The lighthouse validator client #$index returns an error. The last 10 lines of the log file is shown below.\n\n$(tail -n 10 $log_file)"
    exit 1
fi
