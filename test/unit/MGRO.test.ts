import { expect } from 'chai';
import { ethers } from 'hardhat';
import type { MGRO } from '../../typechain-types';

const MAX_SUPPLY = 1_000_000_000n * 10n ** 18n;

describe('MGRO', function () {
  async function deployFixture() {
    const [admin, minter, alice, bob] = await ethers.getSigners();
    const factory = await ethers.getContractFactory('MGRO');
    const mgro = (await factory.deploy(admin.address)) as MGRO;
    await mgro.waitForDeployment();

    const minterRole = await mgro.MINTER_ROLE();
    await mgro.connect(admin).grantRole(minterRole, minter.address);

    return { mgro, admin, minter, alice, bob, minterRole };
  }

  describe('deployment', function () {
    it('sets MAX_SUPPLY and cap to 1 billion tokens', async function () {
      const { mgro } = await deployFixture();
      expect(await mgro.MAX_SUPPLY()).to.equal(MAX_SUPPLY);
      expect(await mgro.cap()).to.equal(MAX_SUPPLY);
      expect(await mgro.totalSupply()).to.equal(0n);
    });

    it('reverts when admin is zero address', async function () {
      const factory = await ethers.getContractFactory('MGRO');
      await expect(
        factory.deploy(ethers.ZeroAddress)
      ).to.be.revertedWithCustomError(factory, 'MGRO__InvalidInput');
    });
  });

  describe('mint', function () {
    it('mints to a recipient when caller has MINTER_ROLE', async function () {
      const { mgro, minter, alice } = await deployFixture();
      const amount = ethers.parseEther('100');

      await expect(mgro.connect(minter).mint(alice.address, amount))
        .to.emit(mgro, 'Transfer')
        .withArgs(ethers.ZeroAddress, alice.address, amount);

      expect(await mgro.balanceOf(alice.address)).to.equal(amount);
      expect(await mgro.totalSupply()).to.equal(amount);
    });

    it('reverts when caller lacks MINTER_ROLE', async function () {
      const { mgro, alice } = await deployFixture();
      await expect(mgro.connect(alice).mint(alice.address, 1n)).to.be.reverted;
    });

    it('reverts on zero address or zero amount', async function () {
      const { mgro, minter, alice } = await deployFixture();

      await expect(
        mgro.connect(minter).mint(ethers.ZeroAddress, 1n)
      ).to.be.revertedWithCustomError(mgro, 'MGRO__InvalidInput');
      await expect(
        mgro.connect(minter).mint(alice.address, 0n)
      ).to.be.revertedWithCustomError(mgro, 'MGRO__InvalidInput');
    });

    it('reverts when mint would exceed the supply cap', async function () {
      const { mgro, minter, alice } = await deployFixture();

      await expect(
        mgro.connect(minter).mint(alice.address, MAX_SUPPLY + 1n)
      ).to.be.revertedWithCustomError(mgro, 'ERC20ExceededCap');
    });

    it('allows minting again after burns free supply headroom', async function () {
      const { mgro, minter, alice } = await deployFixture();
      const amount = ethers.parseEther('10');

      await mgro.connect(minter).mint(alice.address, amount);
      await mgro.connect(alice).burn(amount);
      await mgro.connect(minter).mint(alice.address, amount);

      expect(await mgro.totalSupply()).to.equal(amount);
      expect(await mgro.balanceOf(alice.address)).to.equal(amount);
    });
  });

  describe('burn', function () {
    it('lets holders burn their own tokens', async function () {
      const { mgro, minter, alice } = await deployFixture();
      const amount = ethers.parseEther('25');

      await mgro.connect(minter).mint(alice.address, amount);
      await expect(mgro.connect(alice).burn(amount))
        .to.emit(mgro, 'Transfer')
        .withArgs(alice.address, ethers.ZeroAddress, amount);

      expect(await mgro.balanceOf(alice.address)).to.equal(0n);
      expect(await mgro.totalSupply()).to.equal(0n);
    });

    it('reverts when balance is insufficient', async function () {
      const { mgro, alice } = await deployFixture();
      await expect(mgro.connect(alice).burn(1n)).to.be.revertedWithCustomError(
        mgro,
        'ERC20InsufficientBalance'
      );
    });
  });

  describe('burnFrom', function () {
    it('burns from an approved account', async function () {
      const { mgro, minter, alice, bob } = await deployFixture();
      const amount = ethers.parseEther('15');

      await mgro.connect(minter).mint(alice.address, amount);
      await mgro.connect(alice).approve(bob.address, amount);

      await expect(mgro.connect(bob).burnFrom(alice.address, amount))
        .to.emit(mgro, 'Transfer')
        .withArgs(alice.address, ethers.ZeroAddress, amount);

      expect(await mgro.balanceOf(alice.address)).to.equal(0n);
      expect(await mgro.allowance(alice.address, bob.address)).to.equal(0n);
    });

    it('reverts without sufficient allowance', async function () {
      const { mgro, minter, alice, bob } = await deployFixture();
      const amount = ethers.parseEther('5');

      await mgro.connect(minter).mint(alice.address, amount);
      await expect(
        mgro.connect(bob).burnFrom(alice.address, amount)
      ).to.be.revertedWithCustomError(mgro, 'ERC20InsufficientAllowance');
    });
  });
});
