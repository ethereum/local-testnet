source ./vars.env

el_data_dir() {
    el_data_dir="$ROOT/node$1/ethereum"
}

cl_data_dir() {
    cl_data_dir="$ROOT/node$1/lighthouse"
}

node_error() {
    echo -e "\n*Node Error!*: $1\n"
}
