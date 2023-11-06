// const { expect } = require("chai");
// const { ethers } = require("hardhat");

// describe("MGRO test", function () {
//   let owner, user1, Minter, MGRO, Management, MGRADD, NFTADD, MGMT;

//   beforeEach(async function () {
//     [owner, user1] = await ethers.getSigners();
//     Minter = await ethers.getContractFactory('MyToken');
//     MGRO = await ethers.getContractFactory('MGROW');
//     Management = await ethers.getContractFactory('Management');

//     MGRADD = await MGRO.deploy();
//     NFTADD = await Minter.deploy();
//     const tokenAddress = await MGRADD.getAddress();
//     const NFTAddress = await NFTADD.getAddress();

//     MGMT = await Management.deploy(NFTAddress, tokenAddress);
//     const mgtAddress = await MGMT.getAddress();

//     // Set the Management contract address in MGRADD and NFTADD
//     await MGRADD.setManagementContract(mgtAddress);
//     await NFTADD.setManagementContract(mgtAddress);

//     // Add base URIs
//     await MGMT.addBaseURI("ipfs://QmW3h5dB7yKyacNDfo1XCjjWV5zFyeDZfeVYcpYbx1xuNP");
//     await MGMT.addBaseURI("ipfs://Qmbza7VprgNZ8eWzjRFWBaZUj11tZ2kEHVA6VUZGnsGVtu/");
//     await MGMT.addBaseURI("ipfs://QmaHhmm9bwJSF95NDwqyFiCX3LPDi7g6vY2zNXxQuDqgXe/");
//   });

//   describe("Management Contracts Setup", function () {
//   it("Both the minter and MGRO should have the MGMT contract set", async function () {
//     const mgtAddress = await MGMT.getAddress();

//     expect(await NFTADD.management()).to.equal(mgtAddress);
//     expect(await MGRADD.management()).to.equal(mgtAddress);
//   });

// });
// describe("ERC20 Token Minting and Burning", function () {
//   it("The ERC20 Contract should only allow minting if it is called by the management contract", async function(){
//     await expect(MGMT.mintTokens(owner.address, ethers.parseEther('10'))).to.not.be.reverted;
//     await expect(MGRADD.mintTokens(owner.address, ethers.parseEther('10'))).to.be.revertedWith("Unauthorized");
//   });

//   it("Once the Management Contract mints, the owner address balance should be increased, and the stats updated", async function(){
//     await MGMT.mintTokens(owner.address, ethers.parseEther('10'));
//     expect(await MGRADD.balanceOf(owner.address)).to.equal(ethers.parseEther('10'));
//     const [minted, burnt] = await MGMT.checkStats(owner.address);
//     expect(minted).to.be.equal(ethers.parseEther('10'));
//     expect(burnt).to.be.equal(0);
//   });

//   it('User Should be able to burn tokens from the management contract', async function () {
//     await MGRADD.approve(owner.address, ethers.parseEther('100'));
//     await MGMT.mintTokens(owner.address, ethers.parseEther('10'));

//     expect(await MGRADD.balanceOf(owner.address)).to.equal(ethers.parseEther('10'));

//     await MGMT.burnTokens(ethers.parseEther('5'));
//     expect(await MGRADD.balanceOf(owner.address)).to.equal(ethers.parseEther('5'));

//     const [minted, burnt] = await MGMT.checkStats(owner.address);
//     expect(minted).to.be.equal(ethers.parseEther('10'));
//     expect(burnt).to.be.equal(ethers.parseEther('5'));
//   });

//   it("Should not change the stats values if the tokens are transferred", async function () {
//     await MGRADD.approve(owner.address, ethers.parseEther('100'));
//     await MGMT.mintTokens(owner.address, ethers.parseEther('10'));
//     await MGMT.burnTokens(ethers.parseEther('5'));
//     await MGRADD.transfer(user1.address, ethers.parseEther('2'));

//     expect(await MGRADD.balanceOf(owner.address)).to.equal(ethers.parseEther('3'));
//     expect(await MGRADD.balanceOf(user1.address)).to.equal(ethers.parseEther('2'));

//     const [minted, burnt] = await MGMT.checkStats(owner.address);
//     expect(minted).to.be.equal(ethers.parseEther('10'));
//     expect(burnt).to.be.equal(ethers.parseEther('5'));

//     const [minted1, burnt1] = await MGMT.checkStats(user1.address);
//     expect(minted1).to.be.equal(0);
//     expect(burnt1).to.be.equal(0);
//   });

//   it("Users can burn tokens only through the management contract", async function(){
//     await MGRADD.approve(owner.address, ethers.parseEther('100'));
//     await MGMT.mintTokens(owner.address, ethers.parseEther('10'));

//     await expect(MGMT.burnTokens(ethers.parseEther('5'))).to.not.be.reverted;
//     await expect(MGRADD.burnTokens(owner.address, ethers.parseEther('5'))).to.be.revertedWith("Unauthorized");
//   });

// });

// describe("Base URI Management", function () {
//   it("Should allow owner to set the base URIs", async function(){
//     expect(await MGMT.checklength()).to.equal(3);
//   });

//   it("Should not allow more than 3 URIs", async function(){
//     await expect(MGMT.addBaseURI("ipfs://QmaHhmm9bwJSF95NDwqyFiCX3LPDi7g6vY2zfhjdfgnXe")).to.be.revertedWith("Cannot have more than 3 URIs");
//   });

// });

// describe("NFT Minting and URI Updates", function () {
//   it("Users should be able to mint NFTs, and tokenId added to array of owned tokens", async function(){
//     await MGMT.mintNFTs();
//     expect(await NFTADD.balanceOf(owner.address)).to.be.equal(1);
//     expect(await MGMT.checkUserNFTs(owner.address)).to.be.equal(1);
//   });

//   it("Check for the Minted NFT to be set to the baseURI[0] on mint", async function(){
//     await MGMT.mintNFTs();
//     expect(await NFTADD.tokenURI(1)).to.equal("ipfs://QmW3h5dB7yKyacNDfo1XCjjWV5zFyeDZfeVYcpYbx1xuNP");
//   });

//   it("Should update the URI if the minted is greater than burnt", async function(){
//     await MGMT.mintNFTs();
//     expect(await NFTADD.tokenURI(1)).to.equal("ipfs://QmW3h5dB7yKyacNDfo1XCjjWV5zFyeDZfeVYcpYbx1xuNP");
//     await MGMT.mintTokens(owner.address, ethers.parseEther('50'));
//     await MGMT.burnTokens(ethers.parseEther('25'));
//     await MGMT.updateNFTs(owner.address);
//     expect(await NFTADD.tokenURI(1)).to.equal("ipfs://Qmbza7VprgNZ8eWzjRFWBaZUj11tZ2kEHVA6VUZGnsGVtu/2/1");
//   });
//   it("Should update the URI if the minted is greater than burnt and minted is greater than 100", async function(){
//     await MGMT.mintNFTs();
//     expect(await NFTADD.tokenURI(1)).to.equal("ipfs://QmW3h5dB7yKyacNDfo1XCjjWV5zFyeDZfeVYcpYbx1xuNP");
//     await MGMT.mintTokens(owner.address, ethers.parseEther('100'));
//     await MGMT.burnTokens(ethers.parseEther('50'));
//     await MGMT.updateNFTs(owner.address);
//     expect(await NFTADD.tokenURI(1)).to.equal("ipfs://Qmbza7VprgNZ8eWzjRFWBaZUj11tZ2kEHVA6VUZGnsGVtu/2/2");
//   });
//   it("Should update the URI if the minted is greater than burnt and minted is greater than 150", async function(){
//     await MGMT.mintNFTs();
//     expect(await NFTADD.tokenURI(1)).to.equal("ipfs://QmW3h5dB7yKyacNDfo1XCjjWV5zFyeDZfeVYcpYbx1xuNP");
//     await MGMT.mintTokens(owner.address, ethers.parseEther('150'));
//     await MGMT.burnTokens(ethers.parseEther('25'));
//     await MGMT.updateNFTs(owner.address);
//     expect(await NFTADD.tokenURI(1)).to.equal("ipfs://Qmbza7VprgNZ8eWzjRFWBaZUj11tZ2kEHVA6VUZGnsGVtu/5/3");
//   });

//   it("Should update the URI if the burnt is greater than minted", async function(){
//     await MGMT.mintNFTs();
//     expect(await NFTADD.tokenURI(1)).to.equal("ipfs://QmW3h5dB7yKyacNDfo1XCjjWV5zFyeDZfeVYcpYbx1xuNP");
//     await MGMT.mintTokens(owner.address, ethers.parseEther('100'));
//     await MGMT.mintTokens(user1.address, ethers.parseEther('5'));
//     await MGRADD.transfer(user1.address, ethers.parseEther('20'));
//     await MGMT.connect(user1).mintNFTs();
//     await MGMT.connect(user1).burnTokens(ethers.parseEther('10'));
//     await MGMT.updateNFTs(user1.address);

//     const [minted, burnt] = await MGMT.checkStats(user1.address);
//     expect(burnt).to.be.greaterThan(minted);
//     expect(await NFTADD.tokenURI(2)).to.equal("ipfs://QmaHhmm9bwJSF95NDwqyFiCX3LPDi7g6vY2zNXxQuDqgXe/2/1");
//   });
 
// });
// });
