// transaction_trace.js
const { ethers } = require('ethers');
const abi = require('../artifacts/contracts/facets/ManagementFacet.sol/ManagementFacet.json')
const ownerAbi = require('../artifacts/contracts/facets/OwnershipFacet.sol/OwnershipFacet.json')
// Connect to your local Ethereum Execution Layer (EL)
const provider = new ethers.providers.JsonRpcProvider('https://eth-sepolia.g.alchemy.com/v2/AvrIkafWEUKzbxPxkPQJh55e99WFgqO-');

// Replace these private keys with your devnet accounts
const senderPrivateKey = 'dc3f8714779b130ee23e1e74a6a2f6863e07a3b90c91ab8e855f48a8e17facc1';


const wallet = new ethers.Wallet(senderPrivateKey, provider);
console.log(wallet.address)
const Management = new ethers.Contract('0x9C03D6189660fBEF2Df3Cf4e57e5d4c00F10886f',abi.abi, wallet)
const ownership = new ethers.Contract('0x9C03D6189660fBEF2Df3Cf4e57e5d4c00F10886f', ownerAbi.abi,wallet)
async function sendTransaction() {
    console.log('Sending transaction...');

    // const owner = await ownership.owner()
    // console.log("owner: ", owner)
    // await ownership.transferOwnership('0x11ec36418bE9a610904D1409EF0577b645104881')
    // const uris = await Management.checklength()

    // console.log(uris)

    //  await Management.addBaseURI("ipfs://QmXzFFAoqVuNvmHhGjHf83fuPoNcYchgqnoApQ7TQrawdH/");
    //   await Management.addBaseURI("ipfs://QmbiW58L447GyaHnSgAtfPv5HwpxSd4N6fptGDrQFXMbPt/");
    //   await Management.addBaseURI("ipfs://QmV7hEVZqAbnHZcAfg8pVqXJNEdX9two2gisSQkfTNbEbS/");
    // await Management.mintNFT('0x11ec36418bE9a610904D1409EF0577b645104881')


        await Management.setVerificationContract('0xb50319d25a2d7eBc0e50CFEb8332283923684294');
   
 





    // Log detailed receipt
}

sendTransaction().catch(console.error);