// SPDX-License-Identifier: MIT


const { expect } =require("chai");
const { ethers } = require( "hardhat");
// import { Signer } from "ethers";
// import { BigNumber } from "ethers";

describe("SimpleStaking", () => {
    let SimpleStaking, simpleStaking, Token;
    let owner, staker1, staker2;

    const initialSupply = ethers.utils.parseEther("1000000");
    const stakeAmount = ethers.utils.parseEther("1000");
    const slashingPercentage = 10; // 10%

    beforeEach(async () => {
        [owner, staker1, staker2] = await ethers.getSigners();

        const TokenFactory = await ethers.getContractFactory("TGNToken"); // Replace with your actual token contract
        Token = await TokenFactory.connect(owner).deploy();
        // await Token.mint(staker1.address, stakeAmount);
        // await Token.mint(staker2.address, stakeAmount);
        await Token.mint(owner.address, initialSupply);
        const SimpleStakingFactory = await ethers.getContractFactory("SimpleStaking");
        SimpleStaking = await SimpleStakingFactory.connect(owner).deploy(Token.address, owner.address);

        // Transfer some tokens to stakers for testing
        await Token.connect(owner).transfer(staker1.address, stakeAmount.mul(2));
        await Token.connect(owner).transfer(staker2.address, stakeAmount.mul(3));
    });

    it("should allow staking and check staked balance", async () => {
        await Token.connect(staker1).approve(SimpleStaking.address, stakeAmount);
        await SimpleStaking.connect(staker1).stake(stakeAmount);

        const stakedBalance = await SimpleStaking.getStakedBalance(staker1.address);
        expect(stakedBalance).to.equal(stakeAmount, "Incorrect staked balance");
    });

    it("should allow unstaking and check unstaked balance", async () => {
        await Token.connect(staker1).approve(SimpleStaking.address, stakeAmount);
        await SimpleStaking.connect(staker1).stake(stakeAmount);

        await SimpleStaking.connect(staker1).unstake(stakeAmount);

        const stakedBalance = await SimpleStaking.getStakedBalance(staker1.address);
        expect(stakedBalance).to.equal(0, "Incorrect staked balance after unstaking");
    });

    it("should allow slashing by DAO", async () => {

        await SimpleStaking.connect(owner).setSlashingParams(10);


        await Token.connect(staker1).approve(SimpleStaking.address, stakeAmount);

        await SimpleStaking.connect(staker1).stake(stakeAmount);

        const initialBalance = await SimpleStaking.getStakedBalance(staker1.address);

        await SimpleStaking.connect(owner).slash(staker1.address);

        const finalBalance = await SimpleStaking.getStakedBalance(staker1.address);

        const expectedSlashAmount = initialBalance.mul(slashingPercentage).div(100);
        expect(finalBalance).to.equal(initialBalance.sub(expectedSlashAmount), "Incorrect staked balance after slashing");
    });

    it("should not allow slashing when slashing is disabled", async () => {
        await SimpleStaking.connect(owner).setSlashingEnabled(false);

        await Token.connect(staker1).approve(SimpleStaking.address, stakeAmount);
        await SimpleStaking.connect(staker1).stake(stakeAmount);

        const initialBalance = await SimpleStaking.getStakedBalance(staker1.address);

        await expect( SimpleStaking.connect(owner).slash(staker1.address)).to.be.revertedWith("Slashing is currently disabled");

        const finalBalance = await SimpleStaking.getStakedBalance(staker1.address);
        expect(finalBalance).to.equal(initialBalance, "Staked balance should remain unchanged");
    });

    it("should only allow DAO to set slashing parameters", async () => {
        await expect(SimpleStaking.connect(staker1).setSlashingParams(slashingPercentage)).to.be.revertedWith("Caller is not the DAO contract");
    });
    
    it("should only allow DAO to enable/disable slashing", async () => {
        await expect(SimpleStaking.connect(staker1).setSlashingEnabled(true)).to.be.revertedWith("Caller is not the DAO contract");
    });
    
    it("should revert when trying to stake without approving allowance", async () => {
        await expect(SimpleStaking.connect(staker1).stake(stakeAmount)).to.be.revertedWith("Please increase the allowance for this contract");
    });
    
    it("should revert when trying to unstake more than the staked balance", async () => {
        await Token.connect(staker1).approve(SimpleStaking.address, stakeAmount);
        await SimpleStaking.connect(staker1).stake(stakeAmount);
    
        await expect(SimpleStaking.connect(staker1).unstake(stakeAmount.mul(2))).to.be.revertedWith("Not enough staked balance");
    });
    
    it("should not allow slashing with zero slashing percentage", async () => {
        await expect(SimpleStaking.connect(owner).setSlashingParams(0)).to.be.revertedWith("Invalid Input");
    });
    
    it("should not allow slashing a staker with zero balance", async () => {
        await expect(SimpleStaking.connect(owner).slash(staker1.address)).to.be.revertedWith("Cannot slash zero balance");
    });
    
    it("should not allow slashing with slash amount exceeding staked balance", async () => {
        await Token.connect(staker1).approve(SimpleStaking.address, stakeAmount);
        await SimpleStaking.connect(staker1).stake(stakeAmount);
    
        await SimpleStaking.connect(owner).setSlashingParams(110); // Set slashing percentage to an invalid value
    
        await expect(SimpleStaking.connect(owner).slash(staker1.address)).to.be.revertedWith("Slash amount exceeds staked balance");
    });
    
  
    
});
