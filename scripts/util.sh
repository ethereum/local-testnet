NODE_COUNT=2
GENESIS_TEMPLATE_FILE=./genesis.template.json
ROOT=./data
NETWORK_ID=$(cat $GENESIS_TEMPLATE_FILE | jq '.config.chainId')

BOOT_KEY_FILE=$ROOT/boot.key
BOOT_LOG_FILE=$ROOT/bootnode.log
GENESIS_FILE=$ROOT/genesis.json

BASE_GETH_PORT=21000
BASE_GETH_RPC_PORT=8600

el_data_dir() {
    el_data_dir="$ROOT/node$1/ethereum"
}

cl_data_dir() {
    cl_data_dir="$ROOT/node$1/lighthouse"
}

node_error() {
    echo -e "\n*Node Error!*: $1\n"
}
