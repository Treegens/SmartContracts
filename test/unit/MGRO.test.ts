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

  describe('permit (EIP-2612)', function () {
    async function signPermit(
      mgro: MGRO,
      owner: {
        address: string;
        signTypedData: typeof ethers.Wallet.prototype.signTypedData;
      },
      spender: string,
      value: bigint,
      deadline: bigint
    ) {
      const network = await ethers.provider.getNetwork();
      const nonce = await mgro.nonces(owner.address);
      const domain = {
        name: 'MGRO',
        version: '1',
        chainId: network.chainId,
        verifyingContract: await mgro.getAddress()
      };
      const types = {
        Permit: [
          { name: 'owner', type: 'address' },
          { name: 'spender', type: 'address' },
          { name: 'value', type: 'uint256' },
          { name: 'nonce', type: 'uint256' },
          { name: 'deadline', type: 'uint256' }
        ]
      };
      const message = {
        owner: owner.address,
        spender,
        value,
        nonce,
        deadline
      };
      const signature = await owner.signTypedData(domain, types, message);
      return ethers.Signature.from(signature);
    }

    it('sets allowance via signature', async function () {
      const { mgro, minter, alice, bob } = await deployFixture();
      const amount = ethers.parseEther('20');
      const deadline = ethers.MaxUint256;

      await mgro.connect(minter).mint(alice.address, amount);
      const { v, r, s } = await signPermit(
        mgro,
        alice,
        bob.address,
        amount,
        deadline
      );

      await expect(
        mgro.permit(alice.address, bob.address, amount, deadline, v, r, s)
      )
        .to.emit(mgro, 'Approval')
        .withArgs(alice.address, bob.address, amount);

      expect(await mgro.allowance(alice.address, bob.address)).to.equal(amount);
    });

    it('enables permit then burnFrom in two steps', async function () {
      const { mgro, minter, alice, bob } = await deployFixture();
      const amount = ethers.parseEther('12');
      const deadline = ethers.MaxUint256;

      await mgro.connect(minter).mint(alice.address, amount);
      const { v, r, s } = await signPermit(
        mgro,
        alice,
        bob.address,
        amount,
        deadline
      );
      await mgro.permit(alice.address, bob.address, amount, deadline, v, r, s);

      await expect(mgro.connect(bob).burnFrom(alice.address, amount))
        .to.emit(mgro, 'Transfer')
        .withArgs(alice.address, ethers.ZeroAddress, amount);

      expect(await mgro.balanceOf(alice.address)).to.equal(0n);
    });

    it('increments nonce after a successful permit', async function () {
      const { mgro, minter, alice, bob } = await deployFixture();
      const amount = ethers.parseEther('1');
      const deadline = ethers.MaxUint256;

      await mgro.connect(minter).mint(alice.address, amount);
      expect(await mgro.nonces(alice.address)).to.equal(0n);

      const sig = await signPermit(mgro, alice, bob.address, amount, deadline);
      await mgro.permit(
        alice.address,
        bob.address,
        amount,
        deadline,
        sig.v,
        sig.r,
        sig.s
      );

      expect(await mgro.nonces(alice.address)).to.equal(1n);
    });

    it('exposes DOMAIN_SEPARATOR', async function () {
      const { mgro } = await deployFixture();
      const separator = await mgro.DOMAIN_SEPARATOR();
      expect(separator).to.match(/^0x[0-9a-f]{64}$/i);
    });
  });
});
