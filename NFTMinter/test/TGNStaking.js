const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TGN Test", function () {
  let owner, user1, TGNToken, Staking, TGN, STK;

  beforeEach(async function () {
    [owner, user1] = await ethers.getSigners();
    TGNToken = await ethers.getContractFactory('TGNToken');
    Staking = await ethers.getContractFactory('TGNVault');
    

    TGN = await TGNToken.deploy(owner.address);
   
    const tokenAddress = await TGN.getAddress();
    STK = await Staking.deploy(tokenAddress);
    const StakingAddress = await STK.getAddress();

  })
  it("Should allow owner to mint tokens", async function(){
        await TGN.mint(owner.address, ethers.parseEther('10'));

        expect(await TGN.balanceOf(owner.address)).to.equal(ethers.parseEther('10'))
  })
  it("Users can transfer tokens", async function(){
    await TGN.mint(owner.address, ethers.parseEther('10'));

    await TGN.transfer(user1.address, ethers.parseEther('5'));

    expect(await TGN.balanceOf(user1.address)).to.equal(ethers.parseEther('5'))
    expect(await TGN.balanceOf(owner.address)).to.equal(ethers.parseEther('5'))
  })
  it("Should have the correct name, symbol and decimals", async function(){
    const Name = await TGN.name()
    const Sym = await TGN.symbol()

    expect(Name).to.equal("TGNToken");
    expect(Sym).to.equal("TGN")
    expect(await TGN.decimals()).to.equal(18)


  })
  it("Users can approve token usage by another contract", async function(){
    const add = await STK.getAddress()
    await TGN.approve(add, ethers.parseEther('1000'))

    expect(await TGN.allowance(owner.address, add)).to.equal(ethers.parseEther('1000'))
  })
  it("Owner can mint 300M Tokens max", async function(){
    const add = await STK.getAddress()
    await TGN.mint(add, ethers.parseEther('50000000'))
    expect(await TGN.totalSupply()).to.equal(ethers.parseEther('50000000'))
    await TGN.mint(add, ethers.parseEther('250000000'))
    expect(await TGN.totalSupply()).to.equal(ethers.parseEther('300000000'))

    await expect(TGN.mint(add, ethers.parseEther('1'))).to.be.revertedWith('Exceeds max supply')
    
 

  })

})
