const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TGN Test", function () {
  let owner, user1,user2, user3, TGNToken, Staking, TGN, STK;

  beforeEach(async function () {
    [owner, user1, user2, user3] = await ethers.getSigners();
    TGNToken = await ethers.getContractFactory('TGNToken');
    Staking = await ethers.getContractFactory('TGNVault');
    

    TGN = await TGNToken.deploy();
   
    const tokenAddress =  TGN.address;
    STK = await Staking.deploy(tokenAddress);
    const StakingAddress = await STK.address;

  })
  describe("Token Test", function(){
  it("Should allow owner to mint tokens", async function(){
        await TGN.mint(owner.address, ethers.utils.parseEther('10'));

        expect(await TGN.balanceOf(owner.address)).to.equal(ethers.utils.parseEther('10'))
  })
  it("Users can transfer tokens", async function(){
    await TGN.mint(owner.address, ethers.utils.parseEther('10'));

    await TGN.transfer(user1.address, ethers.utils.parseEther('5'));

    expect(await TGN.balanceOf(user1.address)).to.equal(ethers.utils.parseEther('5'))
    expect(await TGN.balanceOf(owner.address)).to.equal(ethers.utils.parseEther('5'))
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
    await TGN.mint(add, ethers.utils.parseEther('50000000'))
    expect(await TGN.totalSupply()).to.equal(ethers.utils.parseEther('50000000'))
    await TGN.mint(add, ethers.utils.parseEther('250000000'))
    expect(await TGN.totalSupply()).to.equal(ethers.utils.parseEther('300000000'))

    await expect(TGN.mint(add, ethers.utils.parseEther('1'))).to.be.revertedWith('Exceeds max supply')
    
 

  })
  it("Should send the staking address tokens", async function(){
    const add = await STK.address
    await TGN.mint(add, ethers.utils.parseEther('50000000'))

    expect(await TGN.balanceOf(add)).to.equal(ethers.utils.parseEther('50000000'))

  })
})
 describe("Pre-Staking Vault Tests", function(){
  it("Should take in addresses and amounts for the pre-stake", async function(){
    const add = await STK.address
    await TGN.mint(add, ethers.utils.parseEther('50000000'))
    await STK.allocateTokens([user1.address, user2.address, user3.address], [ethers.utils.parseEther('500'),ethers.utils.parseEther('1000'),ethers.utils.parseEther('600')])

    expect(await STK.checkAllocation(user1.address)).to.equal(ethers.utils.parseEther('500'))
    expect(await STK.checkAllocation(user2.address)).to.equal(ethers.utils.parseEther('1000'))
    expect(await STK.checkAllocation(user3.address)).to.equal(ethers.utils.parseEther('600'))

  })
  it("Should not allow a user to claim until 15th January", async function(){
    const add = await STK.address
    await TGN.mint(add, ethers.utils.parseEther('50000000'))
    await STK.allocateTokens([user1.address, user2.address, user3.address], [ethers.utils.parseEther('500'),ethers.utils.parseEther('1000'),ethers.utils.parseEther('600')])

    await expect( STK.connect(user1).claimTokens()).to.be.revertedWith("Tokens can't be claimed yet")
    await network.provider.send("evm_setNextBlockTimestamp", [1705490015]);
    await expect( STK.connect(user1).claimTokens()).to.not.be.reverted


    
  })
  it("Should not allow a user to claim without an allocation", async function(){
    const add = await STK.address
    await TGN.mint(add, ethers.utils.parseEther('50000000'))
    await STK.allocateTokens([user1.address, user2.address, user3.address], [ethers.utils.parseEther('500'),ethers.utils.parseEther('1000'),ethers.utils.parseEther('600')])
    //await network.provider.send("evm_setNextBlockTimestamp", [1705490015]);
    await expect(STK.claimTokens()).to.be.revertedWith("No tokens allocated to this address")

  })
  it("Should not allow users to claim more than once", async function(){
    const add = await STK.address
    await TGN.mint(add, ethers.utils.parseEther('50000000'))
    await STK.allocateTokens([user1.address, user2.address, user3.address], [ethers.utils.parseEther('500'),ethers.utils.parseEther('1000'),ethers.utils.parseEther('600')])
    //await network.provider.send("evm_setNextBlockTimestamp", [1705490015]);
    await (STK.connect(user2).claimTokens())

    expect(await STK.checkClaimStatus(user2.address)).to.equal(true)
    
  })
 })

})
