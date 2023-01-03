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

    // The contract is different from the one in the mainnet.
    // Please see "https://etherscan.io/tx/0xe75fb554e433e03763a1560646ee22dcb74e5274b34c5ad644e7c0f619a7e1d0".
    // The current one is "v0.12.1". Look at https://github.com/ethereum/consensus-specs/tree/v0.12.1
    const jsonInterface = JSON.parse(fs.readFileSync('./deposit-contract.json'));
    const bytecode = JSON.parse(fs.readFileSync('./deposit-contract.bytecode'));
    const undeployed = new web3.eth.Contract(jsonInterface);
    // The real gasLimit is 3,141,592 and the real gasPrice is 147 Gwei
    const contract = await undeployed
        .deploy({ data: bytecode })
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
