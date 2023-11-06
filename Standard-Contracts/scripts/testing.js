const {abi} = require('../artifacts/contracts/nftMinter.sol/MyToken.json')
const {ethers} = require('ethers')

// Polygon configuration
const polygonRPC = "https://polygon-mumbai.g.alchemy.com/v2/EiEk6hXCVsVB1cy6VIPlNdVaH8qNkCiZ";
const polygonProvider = new ethers.JsonRpcProvider(polygonRPC);
const rKey ='db71b39375e0efaf240b24f89cb14d32d07c6679ea5a06ae4a52dc6ed806c401';
const polygonWallet = new ethers.Wallet(rKey, polygonProvider);
const CA = "0xD6AD823f074d797988C153a0Bf682e9828F1cD6f";
const polygonContract = new ethers.Contract(CA, abi, polygonWallet);

async function mintToken() {
const owner  = '0x34d235fC47593EA72A493804FEd11C1499A7826C'

await polygonContract.safeMint(owner, 1);


    
}
//mintToken()

async function update(minted, burnt) {

    await polygonContract.updateImg(minted, burnt, 1);

}
update(1,2)