// const { expect } = require("chai");
// const { ethers } = require("hardhat");

// describe("Lock", function () {
//   let owner, user1, user2, Minter;

//   beforeEach(async function () {
//     [owner, user1, user2] = await ethers.getSigners();
//     Minter = await ethers.getContractFactory('MyToken');
   
//   });

//   describe("Deploy and Mint", async function () {
//     it("should mint a token with the correct URI", async function () {
//       const minterInstance = await Minter.deploy(owner.address, owner.address);


//       await minterInstance.safeMint(owner.address, 1);
//       const URI = await minterInstance.tokenURI(1);

//       expect(URI).to.equal("ipfs://Qmbza7VprgNZ8eWzjRFWBaZUj11tZ2kEHVA6VUZGnsGVtu/1.json");
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
