/* global describe it before ethers */

const {
  getSelectors,
  FacetCutAction,
  removeSelectors,
  findAddressPositionInFacets
} = require('../scripts/libraries/diamond.js')

const { deployDiamond } = require('../scripts/deploy.js')
const { ethers } = require("hardhat");

const { expect, assert } = require('chai')

describe('DiamondTest', async function () {
  let owner, user1, Minter, MGRO, Management, MGRADD, NFTADD
  let diamondAddress
  let diamondCutFacet
  let diamondLoupeFacet
  let ownershipFacet
  let managementFacet
  let tx
  let receipt
  let result
  const addresses = []

  before(async function () {
      // Get signers
      [owner, user1, ] = await ethers.getSigners();
      // Deploy the Diamond contract
      diamondAddress = await deployDiamond();
      // Get contract instances
      diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress);
      diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress);
      ownershipFacet = await ethers.getContractAt('OwnershipFacet', diamondAddress);
      managementFacet = await ethers.getContractAt('ManagementFacet', diamondAddress);

      console.log("We good till this point")
      // Deploy Minter and MGRO contracts
      Minter = await ethers.getContractFactory('TreegenNFT');
      MGRO = await ethers.getContractFactory('MGRO');
      MGRADD = await MGRO.deploy();
      console.log("Good, " ,MGRADD.address)
      NFTADD = await Minter.deploy("example://uri");
      
      // Get token addresses
      const tokenAddress = MGRADD.address;
      const NFTAddress = NFTADD.address;

      // Initialize Management Facet
      await managementFacet.initialize(NFTAddress, tokenAddress, owner.address, MGRADD.address );

      // Set the Management contract address in MGRADD and NFTADD
      await MGRADD.setManagementContract(diamondAddress);
      await NFTADD.setManagementContract(diamondAddress);

      // Add base URIs
      await managementFacet.addBaseURI("ipfs://QmW3h5dB7yKyacNDfo1XCjjWV5zFyeDZfeVYcpYbx1xuNP/");
      await managementFacet.addBaseURI("ipfs://Qmbza7VprgNZ8eWzjRFWBaZUj11tZ2kEHVA6VUZGnsGVtu/");
      await managementFacet.addBaseURI("ipfs://QmaHhmm9bwJSF95NDwqyFiCX3LPDi7g6vY2zNXxQuDqgXe/");
      
  })

  it('should have 4 facets -- call to facetAddresses function', async () => {
      for (const address of await diamondLoupeFacet.facetAddresses()) {
          addresses.push(address);
      }

      assert.equal(addresses.length, 4);
  })

  it('facets should have the right function selectors -- call to facetFunctionSelectors function', async () => {
      let selectors = getSelectors(diamondCutFacet);

      result = await diamondLoupeFacet.facetFunctionSelectors(addresses[0]);
      assert.sameMembers(result, selectors);

      selectors = getSelectors(diamondLoupeFacet);
      result = await diamondLoupeFacet.facetFunctionSelectors(addresses[1]);
      assert.sameMembers(result, selectors);

      selectors = getSelectors(ownershipFacet);
      result = await diamondLoupeFacet.facetFunctionSelectors(addresses[2]);
      assert.sameMembers(result, selectors);
  })

  it('selectors should be associated to facets correctly -- multiple calls to facetAddress function', async () => {
      assert.equal(
          addresses[0],
          await diamondLoupeFacet.facetAddress('0x1f931c1c')
      );
      assert.equal(
          addresses[1],
          await diamondLoupeFacet.facetAddress('0xcdffacc6')
      );
      assert.equal(
          addresses[1],
          await diamondLoupeFacet.facetAddress('0x01ffc9a7')
      );
      assert.equal(
          addresses[2],
          await diamondLoupeFacet.facetAddress('0xf2fde38b')
      );
  })

  describe("Management Contracts Setup", function () {
      it("Both the minter and MGRO should have the managementFacet contract set", async function () {
          expect(await NFTADD.management()).to.equal(diamondAddress);
          expect(await MGRADD.management()).to.equal(diamondAddress);
      });
  });

  describe("ERC20 Token Minting and Burning", function () {
      before(async function () {
          // Mint some tokens and perform setup here
          await managementFacet.mintTokens(owner.address, 10);
      })

      it("The ERC20 Contract should only allow minting if it is called by the management contract", async function () {
          expect(await MGRADD.balanceOf(owner.address)).to.equal(ethers.utils.parseEther('10'));
          await expect(managementFacet.mintTokens(owner.address, 10)).to.not.be.reverted;
          await expect(MGRADD.mintTokens(owner.address, ethers.utils.parseEther('10'))).to.be.revertedWith("Unauthorized");
      });

      it("Once the Management Contract mints, the owner address balance should be increased, and the stats updated", async function () {
          expect(await MGRADD.balanceOf(owner.address)).to.equal(ethers.utils.parseEther('20'));
          const [minted, burnt] = await managementFacet.checkStats(owner.address);
          expect(minted).to.be.equal(20);
          expect(burnt).to.be.equal(0);
      });

      it('User Should be able to burn tokens from the management contract', async function () {
          await MGRADD.approve(owner.address, ethers.utils.parseEther('100'));
            console.log("Current token balance: ",BigInt(await MGRADD.balanceOf(owner.address)))
          expect(await MGRADD.balanceOf(owner.address)).to.equal(ethers.utils.parseEther('20'));

          await managementFacet.burnTokens(5);
          expect(await MGRADD.balanceOf(owner.address)).to.equal(ethers.utils.parseEther('15'));

          const [minted, burnt] = await managementFacet.checkStats(owner.address);
          expect(minted).to.be.equal(20);
          expect(burnt).to.be.equal(5);
      });

      it("Should not change the stats values if the tokens are transferred", async function () {
          await MGRADD.approve(owner.address, ethers.utils.parseEther('100'));
          await managementFacet.burnTokens(5);
          await MGRADD.transfer(user1.address, ethers.utils.parseEther('2'));

          expect(await MGRADD.balanceOf(owner.address)).to.equal(ethers.utils.parseEther('8'));
          expect(await MGRADD.balanceOf(user1.address)).to.equal(ethers.utils.parseEther('2'));

          const [minted, burnt] = await managementFacet.checkStats(owner.address);
          expect(minted).to.be.equal(20);
          expect(burnt).to.be.equal(10);

          const [minted1, burnt1] = await managementFacet.checkStats(user1.address);
          expect(minted1).to.be.equal(0);
          expect(burnt1).to.be.equal(0);
      });

      it("Users can burn tokens only through the management contract", async function () {
          await MGRADD.approve(owner.address, ethers.utils.parseEther('100'));
          console.log("Current token balance: ",BigInt(await MGRADD.balanceOf(owner.address)))
          await expect(managementFacet.burnTokens(5)).to.not.be.reverted;
          await expect(MGRADD.burnTokens(owner.address, ethers.utils.parseEther('5'))).to.be.revertedWith("Unauthorized");
      });
  });

  describe("Base URI Management", function () {
      it("Should allow owner to set the base URIs", async function () {
          expect(await managementFacet.checklength()).to.equal(3);
      });

      it("Should not allow more than 3 URIs", async function () {
          await expect(managementFacet.addBaseURI("ipfs://QmaHhmm9bwJSF95NDwqyFiCX3LPDi7g6vY2zfhjdfgnXe")).to.be.revertedWith("Cannot have more than 3 URIs");
      });
  });

  describe("NFT Minting and URI Updates", function () {
      before(async function () {
          // Mint some tokens and perform setup here
          await managementFacet.mintNFT();
      });

      it("Users should be able to mint NFTs, and tokenId added to array of owned tokens", async function () {
          expect(await NFTADD.balanceOf(owner.address)).to.be.equal(1);
          expect(await managementFacet.checkUserNFTs(owner.address)).to.be.equal(1);
          console.log("User holds: ", (await managementFacet.checkStats(owner.address)))
      });

      it("Check for the Minted NFT to be set to the baseURI[0] on mint", async function () {
          expect(await NFTADD.tokenURI(1)).to.equal("ipfs://QmW3h5dB7yKyacNDfo1XCjjWV5zFyeDZfeVYcpYbx1xuNP");
      });

      it("Should update the URI if the minted is greater than burnt", async function () {
          expect(await NFTADD.tokenURI(1)).to.equal("ipfs://QmW3h5dB7yKyacNDfo1XCjjWV5zFyeDZfeVYcpYbx1xuNP");
          await managementFacet.mintTokens(owner.address, ethers.utils.parseEther('30'));
          await managementFacet.burnTokens(ethers.utils.parseEther('10'));
          const [minted, burnt] = await managementFacet.checkStats(owner.address);
          expect(minted).to.be.equal(ethers.utils.parseEther('50'));
          expect(burnt).to.be.equal(ethers.utils.parseEther('25'));
          await managementFacet.updateNFTs(owner.address);
          expect(await NFTADD.tokenURI(1)).to.equal("ipfs://Qmbza7VprgNZ8eWzjRFWBaZUj11tZ2kEHVA6VUZGnsGVtu/2/1");
      });

      it("Should update the URI if the minted is greater than burnt and minted is greater than 100", async function(){
      // expect(await NFTADD.tokenURI(1)).to.equal("ipfs://QmW3h5dB7yKyacNDfo1XCjjWV5zFyeDZfeVYcpYbx1xuNP");
          await managementFacet.mintTokens(owner.address, ethers.utils.parseEther('50'));
          await managementFacet.burnTokens(ethers.utils.parseEther('25'));
          await managementFacet.updateNFTs(owner.address);
          expect(await NFTADD.tokenURI(1)).to.equal("ipfs://Qmbza7VprgNZ8eWzjRFWBaZUj11tZ2kEHVA6VUZGnsGVtu/2/2");
      });
      
      it("Should update the URI if the minted is greater than burnt and minted is greater than 150", async function(){
          await managementFacet.mintNFT();
        // expect(await NFTADD.tokenURI(1)).to.equal("ipfs://QmW3h5dB7yKyacNDfo1XCjjWV5zFyeDZfeVYcpYbx1xuNP");
          await managementFacet.mintTokens(owner.address, ethers.utils.parseEther('50'));
          await managementFacet.burnTokens(ethers.utils.parseEther('25'));
          await managementFacet.updateNFTs(owner.address);
          expect(await NFTADD.tokenURI(1)).to.equal("ipfs://Qmbza7VprgNZ8eWzjRFWBaZUj11tZ2kEHVA6VUZGnsGVtu/2/3");
          expect(await NFTADD.tokenURI(2)).to.equal("ipfs://Qmbza7VprgNZ8eWzjRFWBaZUj11tZ2kEHVA6VUZGnsGVtu/2/3");
      });


      it("Should update the URI if the burnt is greater than minted", async function(){
          //await managementFacet.mintNFTs();
        // expect(await NFTADD.tokenURI(1)).to.equal("ipfs://QmW3h5dB7yKyacNDfo1XCjjWV5zFyeDZfeVYcpYbx1xuNP");
          await managementFacet.mintTokens(owner.address, ethers.utils.parseEther('100'));
          await managementFacet.mintTokens(user1.address, ethers.utils.parseEther('5'));
          await MGRADD.transfer(user1.address, ethers.utils.parseEther('20'));
          await managementFacet.connect(user1).mintNFT();
          await managementFacet.connect(user1).burnTokens(ethers.utils.parseEther('10'));
          await managementFacet.updateNFTs(user1.address);

          const [minted, burnt] = await managementFacet.checkStats(user1.address);
          expect(burnt).to.be.above(minted)
          expect(await NFTADD.tokenURI(3)).to.equal("ipfs://QmaHhmm9bwJSF95NDwqyFiCX3LPDi7g6vY2zNXxQuDqgXe/2/1");
      });
    
});


    
    
  })