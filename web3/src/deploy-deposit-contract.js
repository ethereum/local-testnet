#!/usr/bin/env node

const yargs = require('yargs');
const fs = require('fs');
const net = require('net');
const Web3 = require('web3');

const argv = yargs
    .option('endpoint', {
        description: 'IPC endpoint to which you want to deploy the deposit contract',
        type: 'string',
        demandOption: true,
        requiresArg: true,
    })
    .help()
    .alias('help', 'h').argv;

(async function() {
    const web3 = new Web3(argv.endpoint, net);
    const accounts = await web3.eth.getAccounts();

    // The transaction in the mainnet is at
    // https://etherscan.io/tx/0xe75fb554e433e03763a1560646ee22dcb74e5274b34c5ad644e7c0f619a7e1d0
    const json = JSON.parse(fs.readFileSync('./assets/deposit-contract.json'));
    const undeployed = new web3.eth.Contract(json.abi);
    // The real gasLimit is 3,141,592 and the real gasPrice is 147 Gwei
    const contract = await undeployed
        .deploy({ data: json.bytecode })
        .send({
            from: accounts[0],
            nonce: 0,
            gas: 3141592,
            gasPrice: '147000000000',
        })
        .once('transactionHash', hash => {
            console.log('transaction', hash);
        })
        .once('receipt', receipt => {
            console.log('block_number', receipt.blockNumber);
        });

    console.log('address', contract.options.address);
    process.exit();
})();
