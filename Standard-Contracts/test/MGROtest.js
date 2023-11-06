// const { expect } = require("chai");
// const { ethers } = require("hardhat");

// describe("MGRO test", function () {
//   let owner, user1, user2, Minter, mintAmt;

//   beforeEach(async function () {
//     [owner, user1, user2] = await ethers.getSigners();
//     Minter = await ethers.getContractFactory('MGROW');
//     mintAmt = ethers.parseEther('100')
//     burnAmt = ethers.parseEther('10')
   
//   });
//   it("Should only allow the set address to mint tokens", async function () {
//     const MGROInstance = await Minter.deploy(user2.address);
    
//    await expect(MGROInstance.mintTokens(owner.address,mintAmt )).to.be.revertedWith('Unauthorized')
//    await expect(MGROInstance.connect(user2).mintTokens(user1.address, mintAmt)).to.not.be.reverted
    
//   })
//   it("Owner of tokens can burn their tokens to fund trees", async function(){
//     const MGROInstance = await Minter.deploy(user2.address);
//     await MGROInstance.connect(user2).mintTokens(user1.address, mintAmt)

//     await MGROInstance.connect(user1).burnTokens(burnAmt)
//     expect(await MGROInstance.balanceOf(user1.address)).to.be.equal(ethers.parseEther('90'))

//   })
//   it('Users can freely send MGRO tokens to each other', async function(){
//     const MGROInstance = await Minter.deploy(user2.address);
//     await MGROInstance.connect(user2).mintTokens(user1.address, mintAmt)

//     await MGROInstance.connect(user1).transfer(owner.address, ethers.parseEther('50'))

//     expect(await MGROInstance.balanceOf(user1.address)).to.be.equal(ethers.parseEther('50'))
//     expect(await MGROInstance.balanceOf(owner.address)).to.be.equal(ethers.parseEther('50'))

//     await MGROInstance.connect(owner).transfer(user2.address, ethers.parseEther('50'))
//     expect(await MGROInstance.balanceOf(owner.address)).to.be.equal(ethers.parseEther('0'))
//     expect(await MGROInstance.balanceOf(user2.address)).to.be.equal(ethers.parseEther('50'))



//   })



// });