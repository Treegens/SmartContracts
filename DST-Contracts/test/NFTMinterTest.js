const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TGN Test", function () {
  let owner, user1,user2, user3, TGNToken, Staking, TGN, STK, DAO, TGNDAO, MGRO, MGRADD, verifier;

  beforeEach(async function () {
    [owner, user1, user2, user3,verifier] = await ethers.getSigners();
    TGNToken = await ethers.getContractFactory('TGNToken');
    Staking = await ethers.getContractFactory('TGNVault');
    DAO = await ethers.getContractFactory('TGNDAO');
    MGRO = await ethers.getContractFactory('MGRO');
    MGRADD = await MGRO.deploy();
    

    TGN = await TGNToken.deploy();
   
    const tokenAddress =  TGN.address;
    STK = await Staking.deploy(tokenAddress, owner.address, verifier.address);
    const StakingAddress = await STK.address;

    TGNDAO = await DAO.deploy(tokenAddress,4, 7200,7200,MGRADD.address, StakingAddress );
  })
 
  describe("Token Test", function(){
  it("Should allow owner to mint tokens", async function(){
        await TGN.mintWithTimelock(owner.address, ethers.utils.parseEther('10'), 2705490014);

        expect(await TGN.balanceOf(owner.address)).to.equal(ethers.utils.parseEther('10'))
  })
  it("Users cannot transfer tokens if lock time is yet to elapse", async function(){
    await TGN.mintWithTimelock(owner.address, ethers.utils.parseEther('10'),2705490014);

    await expect(TGN.transfer(user1.address, ethers.utils.parseEther('5'))).to.be.revertedWith("Cannot transfer tokens till unlock time")
    await expect(TGN.transferFrom(owner.address, user1.address, ethers.utils.parseEther('5'))).to.be.revertedWith("Cannot transfer tokens till unlock time")
    // expect(await TGN.balanceOf(user1.address)).to.equal(ethers.utils.parseEther('5'))
    // expect(await TGN.balanceOf(owner.address)).to.equal(ethers.utils.parseEther('5'))
  })
  it("Should have the correct name, symbol and decimals", async function(){
    const Name = await TGN.name()
    const Sym = await TGN.symbol()

    expect(Name).to.equal("TGNToken");
    expect(Sym).to.equal("TGN")
    expect(await TGN.decimals()).to.equal(18)


  })
  it("Users can approve token usage by another contract", async function(){
    const add = await STK.address
    await TGN.approve(add, ethers.utils.parseEther('1000'))

    expect(await TGN.allowance(owner.address, add)).to.equal(ethers.utils.parseEther('1000'))
  })
  it("Owner can mint 300M Tokens max", async function(){
    const add = await STK.address
    await TGN.mintWithTimelock(add, ethers.utils.parseEther('50000000'),2705490014)
    expect(await TGN.totalSupply()).to.equal(ethers.utils.parseEther('50000000'))
    await TGN.mintWithTimelock(add, ethers.utils.parseEther('250000000'), 2705490014)
    expect(await TGN.totalSupply()).to.equal(ethers.utils.parseEther('300000000'))

    await expect(TGN.mintWithTimelock(add, ethers.utils.parseEther('1'), 2705490014)).to.be.revertedWith('Exceeds max supply')
    
 

  })
  
  it("Should only allow the owner to Mint tokens", async function(){
    await expect(TGN.connect(owner).mint(user1.address, ethers.utils.parseEther('10'))).to.not.be.reverted
    await expect(TGN.connect(owner).mintWithTimelock(user1.address, ethers.utils.parseEther('10'),2705490045)).to.not.be.reverted


    await expect(TGN.connect(user1).mint(user1.address, ethers.utils.parseEther('10'))).to.be.reverted

  })



 })

})
