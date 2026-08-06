import { expect } from 'chai';
import { ethers } from 'hardhat';
import type { NonMangroveTreeNFT } from '../../typechain-types';

const MINTER_ROLE = ethers.id('MINTER_ROLE');
const DEFAULT_ADMIN_ROLE = ethers.ZeroHash;

const SAMPLE_RECORD = {
  plantStorageKey: 'submissions/abc123/plant.mp4',
  landStorageKey: 'submissions/abc123/land.mp4',
  treeType: 'oak',
  latitude: 6_524_400,
  longitude: 3_379_200,
  treeCount: 47,
  verifiedAt: 1_721_548_800
};

const METADATA_URL = 'https://cdn.treegens.app/metadata/abc123.json';

describe('NonMangroveTreeNFT', function () {
  let nft: NonMangroveTreeNFT;
  let deployer: Awaited<ReturnType<typeof ethers.getSigners>>[0];
  let minter: Awaited<ReturnType<typeof ethers.getSigners>>[1];
  let planter: Awaited<ReturnType<typeof ethers.getSigners>>[2];
  let stranger: Awaited<ReturnType<typeof ethers.getSigners>>[3];

  const submissionId = ethers.id('submission-abc123');

  beforeEach(async function () {
    [deployer, minter, planter, stranger] = await ethers.getSigners();
    const factory = await ethers.getContractFactory('NonMangroveTreeNFT');
    nft = (await factory.deploy()) as NonMangroveTreeNFT;
    await nft.waitForDeployment();
    await nft.grantRole(MINTER_ROLE, minter.address);
  });

  describe('Deployment', function () {
    it('sets name and symbol', async function () {
      expect(await nft.name()).to.equal('Treegens Tree Planting');
      expect(await nft.symbol()).to.equal('TGTREE');
    });

    it('grants DEFAULT_ADMIN_ROLE to deployer', async function () {
      expect(await nft.hasRole(DEFAULT_ADMIN_ROLE, deployer.address)).to.equal(
        true
      );
    });
  });

  describe('mint', function () {
    it('mints a planting NFT with metadata and on-chain record', async function () {
      await expect(
        nft
          .connect(minter)
          .mint(planter.address, submissionId, METADATA_URL, SAMPLE_RECORD)
      )
        .to.emit(nft, 'PlantingMinted')
        .withArgs(planter.address, 1n, submissionId, METADATA_URL);

      expect(await nft.ownerOf(1)).to.equal(planter.address);
      expect(await nft.tokenURI(1)).to.equal(METADATA_URL);
      expect(await nft.isSubmissionMinted(submissionId)).to.equal(true);
      expect(await nft.submissionIdToToken(submissionId)).to.equal(1n);

      const record = await nft.getPlantingRecord(1);
      expect(record.plantStorageKey).to.equal(SAMPLE_RECORD.plantStorageKey);
      expect(record.landStorageKey).to.equal(SAMPLE_RECORD.landStorageKey);
      expect(record.treeType).to.equal(SAMPLE_RECORD.treeType);
      expect(record.latitude).to.equal(SAMPLE_RECORD.latitude);
      expect(record.longitude).to.equal(SAMPLE_RECORD.longitude);
      expect(record.treeCount).to.equal(SAMPLE_RECORD.treeCount);
      expect(record.verifiedAt).to.equal(SAMPLE_RECORD.verifiedAt);
    });

    it('increments token ids', async function () {
      await nft
        .connect(minter)
        .mint(planter.address, submissionId, METADATA_URL, SAMPLE_RECORD);

      const secondSubmissionId = ethers.id('submission-def456');
      await nft
        .connect(minter)
        .mint(
          planter.address,
          secondSubmissionId,
          'https://cdn.treegens.app/metadata/def456.json',
          {
            ...SAMPLE_RECORD,
            plantStorageKey: 'submissions/def456/plant.mp4'
          }
        );

      expect(await nft.ownerOf(2)).to.equal(planter.address);
    });

    it('reverts when caller lacks MINTER_ROLE', async function () {
      await expect(
        nft
          .connect(stranger)
          .mint(planter.address, submissionId, METADATA_URL, SAMPLE_RECORD)
      ).to.be.reverted;
    });

    it('reverts when submission was already minted', async function () {
      await nft
        .connect(minter)
        .mint(planter.address, submissionId, METADATA_URL, SAMPLE_RECORD);

      await expect(
        nft
          .connect(minter)
          .mint(planter.address, submissionId, METADATA_URL, SAMPLE_RECORD)
      ).to.be.revertedWithCustomError(
        nft,
        'BaseTreePlantingNFT__AlreadyMinted'
      );
    });

    it('reverts for zero recipient', async function () {
      await expect(
        nft
          .connect(minter)
          .mint(ethers.ZeroAddress, submissionId, METADATA_URL, SAMPLE_RECORD)
      ).to.be.revertedWithCustomError(nft, 'BaseTreePlantingNFT__ZeroAddress');
    });

    it('reverts for zero submission id', async function () {
      await expect(
        nft
          .connect(minter)
          .mint(planter.address, ethers.ZeroHash, METADATA_URL, SAMPLE_RECORD)
      ).to.be.revertedWithCustomError(
        nft,
        'BaseTreePlantingNFT__ZeroSubmissionId'
      );
    });

    it('reverts for zero tree count', async function () {
      await expect(
        nft.connect(minter).mint(planter.address, submissionId, METADATA_URL, {
          ...SAMPLE_RECORD,
          treeCount: 0
        })
      ).to.be.revertedWithCustomError(
        nft,
        'BaseTreePlantingNFT__ZeroTreeCount'
      );
    });

    it('reverts for empty plant storage key', async function () {
      await expect(
        nft.connect(minter).mint(planter.address, submissionId, METADATA_URL, {
          ...SAMPLE_RECORD,
          plantStorageKey: ''
        })
      ).to.be.revertedWithCustomError(
        nft,
        'BaseTreePlantingNFT__EmptyPlantStorageKey'
      );
    });

    it('reverts for empty tree type', async function () {
      await expect(
        nft.connect(minter).mint(planter.address, submissionId, METADATA_URL, {
          ...SAMPLE_RECORD,
          treeType: ''
        })
      ).to.be.revertedWithCustomError(
        nft,
        'BaseTreePlantingNFT__EmptyTreeType'
      );
    });

    it('reverts for empty metadata URL', async function () {
      await expect(
        nft
          .connect(minter)
          .mint(planter.address, submissionId, '', SAMPLE_RECORD)
      ).to.be.revertedWithCustomError(
        nft,
        'BaseTreePlantingNFT__EmptyMetadataUrl'
      );
    });

    it('reverts for invalid latitude', async function () {
      await expect(
        nft.connect(minter).mint(planter.address, submissionId, METADATA_URL, {
          ...SAMPLE_RECORD,
          latitude: 91_000_000
        })
      ).to.be.revertedWithCustomError(
        nft,
        'BaseTreePlantingNFT__InvalidLatitude'
      );
    });

    it('reverts for invalid longitude', async function () {
      await expect(
        nft.connect(minter).mint(planter.address, submissionId, METADATA_URL, {
          ...SAMPLE_RECORD,
          longitude: 181_000_000
        })
      ).to.be.revertedWithCustomError(
        nft,
        'BaseTreePlantingNFT__InvalidLongitude'
      );
    });

    it('reverts when reading a non-existent token record', async function () {
      await expect(nft.getPlantingRecord(99)).to.be.reverted;
    });
  });
});
