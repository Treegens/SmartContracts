// const { expect } = require("chai");
// const { ethers } = require("hardhat");

// describe("MGRO test", function () {
//   let owner, user1, Minter, MGRO, Management, MGRADD, NFTADD, MGMT;

//   beforeEach(async function () {
//     [owner, user1] = await ethers.getSigners();
//     Minter = await ethers.getContractFactory('MyToken');
 

  
//     NFTADD = await Minter.deploy();
//     const NFTAddress = await NFTADD.getAddress();

 

//     // Set the Management contract address in MGRADD and NFTADD

//     await NFTADD.setManagementContract(owner.address);

//     // Add base URIs
//     await MGMT.addBaseURI("ipfs://QmW3h5dB7yKyacNDfo1XCjjWV5zFyeDZfeVYcpYbx1xuNP");
//     await MGMT.addBaseURI("ipfs://Qmbza7VprgNZ8eWzjRFWBaZUj11tZ2kEHVA6VUZGnsGVtu/");
//     await MGMT.addBaseURI("ipfs://QmaHhmm9bwJSF95NDwqyFiCX3LPDi7g6vY2zNXxQuDqgXe/");
//   });

//   describe("Deploy and Mint", async function () {
//     it("should mint a token with the correct URI", async function () {
//       const minterInstance = await Minter.deploy();


//       await minterInstance.safeMint(owner.address, 1);
//       const URI = await minterInstance.tokenURI(1);

//       expect(URI).to.equal("ipfs://QmW3h5dB7yKyacNDfo1XCjjWV5zFyeDZfeVYcpYbx1xuNP");
//     });
//     it("Should Update the URI ACCORDINGLY", async function () {
//       const minted = 10;
//       const burnt = 5;
      
//       const minterInstance = await Minter.deploy(owner.address, owner.address);
//       await minterInstance.safeMint(owner.address, 1);

//       await minterInstance.updateImg(minted, burnt, 1)

//       const URI = await minterInstance.tokenURI(1);
//       expect(URI).to.equal("ipfs://Qmbza7VprgNZ8eWzjRFWBaZUj11tZ2kEHVA6VUZGnsGVtu/3.json");

      
//     })

//     it('Upon transfer, the image URI should reset to first Image', async function(){
//       const minted = 10;
//       const burnt = 5;
//       const minterInstance = await Minter.deploy(owner.address, owner.address);
//       await minterInstance.safeMint(owner.address, 1);

//       await minterInstance.updateImg(minted, burnt, 1)

//       const URI = await minterInstance.tokenURI(1);
//       expect(URI).to.equal("ipfs://Qmbza7VprgNZ8eWzjRFWBaZUj11tZ2kEHVA6VUZGnsGVtu/3.json");

//       await minterInstance.transferFrom(owner.address, user1.address, 1)
//       const newURI = await minterInstance.tokenURI(1);
//       expect(newURI).to.equal("ipfs://Qmbza7VprgNZ8eWzjRFWBaZUj11tZ2kEHVA6VUZGnsGVtu/1.json")
//     })
//     it("Only the Management Address can call the UpdateImg Function", async function(){
//       const minted = 10;
//       const burnt = 5;
//       const minterInstance = await Minter.deploy(owner.address, owner.address);
//       await minterInstance.safeMint(owner.address, 1);

//       await expect( minterInstance.updateImg(minted, burnt, 1)).to.not.be.reverted
//       await expect(minterInstance.connect(user1).updateImg(minted,burnt, 1)).to.be.revertedWith("Unauthorized")

//     })
//   });
// });
