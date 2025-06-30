// transaction_trace.js
const { ethers } = require('ethers');
const abi = require('../artifacts/contracts/MGroverification.sol/MGROVerification.json')
const ownerAbi = require('../artifacts/contracts/facets/OwnershipFacet.sol/OwnershipFacet.json')
// Connect to your local Ethereum Execution Layer (EL)
const provider = new ethers.providers.JsonRpcProvider('https://eth-sepolia.g.alchemy.com/v2/AvrIkafWEUKzbxPxkPQJh55e99WFgqO-');

// Replace these private keys with your devnet accounts
const senderPrivateKey = 'dc3f8714779b130ee23e1e74a6a2f6863e07a3b90c91ab8e855f48a8e17facc1';


const wallet = new ethers.Wallet(senderPrivateKey, provider);
console.log(wallet.address)
const verify = new ethers.Contract('0xb50319d25a2d7eBc0e50CFEb8332283923684294',abi.abi, wallet)
const ownership = new ethers.Contract('0xb50319d25a2d7eBc0e50CFEb8332283923684294', ownerAbi.abi,wallet)
async function sendTransaction() {
    console.log('Sending transaction...');



 
        await verify.executeVerification(1);
    
 





    // Log detailed receipt
}

sendTransaction().catch(console.error);