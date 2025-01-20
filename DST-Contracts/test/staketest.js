// SPDX-License-Identifier: MIT


const { expect } =require("chai");
const { ethers } = require( "hardhat");
// import { Signer } from "ethers";
// import { BigNumber } from "ethers";

describe("SimpleStaking", () => {
    let SimpleStaking, simpleStaking, Token;
    let owner, staker1, staker2, mgroVerification;

    const initialSupply = ethers.utils.parseEther("1000000");
    const stakeAmount = ethers.utils.parseEther("1000");
    const slashingPercentage = 10; // 10%

    beforeEach(async () => {
        [owner, staker1, staker2, mgroVerification] = await ethers.getSigners();

        const TokenFactory = await ethers.getContractFactory("TGNToken"); // Replace with your actual token contract
        Token = await TokenFactory.connect(owner).deploy();
        // await Token.mint(staker1.address, stakeAmount);
        // await Token.mint(staker2.address, stakeAmount);
        await Token.mint(owner.address, initialSupply);
        const SimpleStakingFactory = await ethers.getContractFactory("TGNVault");
        SimpleStaking = await SimpleStakingFactory.connect(owner).deploy(Token.address, owner.address , mgroVerification.address);
        console.log(SimpleStaking.address)
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
        expect(stakedBalance).to.equal(0);
    });

    it("should allow slashing by DAO", async () => {

        await SimpleStaking.connect(owner).setSlashingParams(10);


        await Token.connect(staker1).approve(SimpleStaking.address, stakeAmount);

        await SimpleStaking.connect(staker1).stake(stakeAmount);

        const initialBalance = await SimpleStaking.getStakedBalance(staker1.address);

        await SimpleStaking.connect(mgroVerification).slash(staker1.address);

        const finalBalance = await SimpleStaking.getStakedBalance(staker1.address);

        const expectedSlashAmount = initialBalance.mul(slashingPercentage).div(100);
        expect(finalBalance).to.equal(initialBalance.sub(expectedSlashAmount), "Incorrect staked balance after slashing");
    });

    it("should not allow slashing when slashing is disabled", async () => {
        await SimpleStaking.connect(owner).setSlashingEnabled(false);

        await Token.connect(staker1).approve(SimpleStaking.address, stakeAmount);
        await SimpleStaking.connect(staker1).stake(stakeAmount);

        const initialBalance = await SimpleStaking.getStakedBalance(staker1.address);

        await expect( SimpleStaking.connect(mgroVerification).slash(staker1.address)).to.be.reverted;

        const finalBalance = await SimpleStaking.getStakedBalance(staker1.address);
        expect(finalBalance).to.equal(initialBalance, "Staked balance should remain unchanged");
    });

    it("should only allow DAO to set slashing parameters", async () => {
        await expect(SimpleStaking.connect(staker1).setSlashingParams(slashingPercentage)).to.be.reverted;
    });
    
    it("should only allow DAO to enable/disable slashing", async () => {
        await expect(SimpleStaking.connect(staker1).setSlashingEnabled(true)).to.be.reverted;
    });
    
    it("should revert when trying to stake without approving allowance", async () => {
        await expect(SimpleStaking.connect(staker1).stake(stakeAmount)).to.be.reverted;
    });
    
    it("should revert when trying to unstake more than the staked balance", async () => {
        await Token.connect(staker1).approve(SimpleStaking.address, stakeAmount);
        await SimpleStaking.connect(staker1).stake(stakeAmount);
    
         expect( SimpleStaking.connect(staker1).unstake(stakeAmount.mul(2))).to.be.reverted;
    });
    
    it("should not allow slashing with zero slashing percentage", async () => {
        await expect(SimpleStaking.connect(owner).setSlashingParams(0)).to.be.reverted;
    });
    
    it("should not allow slashing a staker with zero balance", async () => {
        await expect(SimpleStaking.connect(owner).slash(staker1.address)).to.be.reverted;
    });
      
    it("should revert if slashing param above 30 is set", async () => {
        await expect(
            SimpleStaking.connect(owner).setSlashingParams(31)
        ).to.be.revertedWith("InvalidInput");
    });

    it("should allow partial staking and partial unstaking", async () => {
        const partialStake = stakeAmount.div(2);

        // Approve and stake half
        await Token.connect(staker1).approve(SimpleStaking.address, stakeAmount);
        await SimpleStaking.connect(staker1).stake(partialStake);

        let staked = await SimpleStaking.getStakedBalance(staker1.address);
        expect(staked).to.equal(partialStake);

        // Stake the other half
        await SimpleStaking.connect(staker1).stake(partialStake);
        staked = await SimpleStaking.getStakedBalance(staker1.address);
        expect(staked).to.equal(stakeAmount);

        // Now unstake only half
        await SimpleStaking.connect(staker1).unstake(partialStake);
        staked = await SimpleStaking.getStakedBalance(staker1.address);
        expect(staked).to.equal(partialStake);
    });

    it("should update lastStakedTime correctly on multiple stakes", async () => {
        await Token.connect(staker1).approve(SimpleStaking.address, stakeAmount.mul(2));

        // First stake
        await SimpleStaking.connect(staker1).stake(stakeAmount);
        const firstStakeTime = await SimpleStaking.getLastStakedTime(staker1.address);

        // Increase time in evm (just to simulate time passing).
        // Hardhat allows us to manipulate time, but we can also just rely on block time.
        await ethers.provider.send("evm_increaseTime", [10]);
        await ethers.provider.send("evm_mine");

        // Second stake
        await SimpleStaking.connect(staker1).stake(stakeAmount);
        const secondStakeTime = await SimpleStaking.getLastStakedTime(staker1.address);

        // Expect the second stake time to be greater than the first
        expect(secondStakeTime).to.be.gt(firstStakeTime);
    });

    it("should not allow a non-mgroVerification address to slash", async () => {
        await SimpleStaking.connect(owner).setSlashingParams(slashingPercentage);

        await Token.connect(staker1).approve(SimpleStaking.address, stakeAmount);
        await SimpleStaking.connect(staker1).stake(stakeAmount);

        // Trying to slash from staker2 (not mgroVerification)
        await expect(
            SimpleStaking.connect(staker2).slash(staker1.address)
        ).to.be.revertedWith("Unauthorized");
    });

    it("should not allow unstaking if lockStaking is set", async () => {
        // 1) Stake
        await Token.connect(staker1).approve(SimpleStaking.address, stakeAmount);
        await SimpleStaking.connect(staker1).stake(stakeAmount);

        // 2) Lock staking from DAO
        await SimpleStaking.connect(owner).setUnstakeLock(true);

        // Attempt to unstake
        await expect(
            SimpleStaking.connect(staker1).unstake(stakeAmount)
        ).to.be.revertedWith("Can't unstake till the voting has passed");
    });

    it("should allow DAO to unlock staking and then allow unstake", async () => {
        // 1) Stake
        await Token.connect(staker1).approve(SimpleStaking.address, stakeAmount);
        await SimpleStaking.connect(staker1).stake(stakeAmount);

        // 2) Lock staking from DAO
        await SimpleStaking.connect(owner).setUnstakeLock(true);

        // 3) Unlock it
        await SimpleStaking.connect(owner).setUnstakeLock(false);

        // 4) Now staker can unstake
        await expect(SimpleStaking.connect(staker1).unstake(stakeAmount))
            .to.emit(SimpleStaking, "Unstaked")
            .withArgs(staker1.address, stakeAmount);

        const stakedBalance = await SimpleStaking.getStakedBalance(staker1.address);
        expect(stakedBalance).to.equal(0);
    });
});
