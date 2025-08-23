/* global ethers */
require('dotenv').config({ path: '../../../.env' })
const { getSelectors } = require('../utils/diamond')

async function main() {
  const [deployer] = await ethers.getSigners()
  console.log('Deployer:', deployer.address)

  // 1. Deploy DiamondCutFacet
  const DiamondCutFacet = await ethers.getContractFactory('DiamondCutFacet')
  const diamondCutFacet = await DiamondCutFacet.deploy()
  await diamondCutFacet.deployed()
  console.log('DiamondCutFacet:', diamondCutFacet.address)

  // 2. Deploy Diamond
  const Diamond = await ethers.getContractFactory('Diamond')
  const diamond = await Diamond.deploy(deployer.address, diamondCutFacet.address)
  await diamond.deployed()
  console.log('Diamond:', diamond.address)

  // 3. Deploy facets
  const OwnershipFacet = await ethers.getContractFactory('OwnershipFacet')
  const ownershipFacet = await OwnershipFacet.deploy()
  await ownershipFacet.deployed()
  console.log('OwnershipFacet:', ownershipFacet.address)

  const DiamondLoupeFacet = await ethers.getContractFactory('DiamondLoupeFacet')
  const diamondLoupeFacet = await DiamondLoupeFacet.deploy()
  await diamondLoupeFacet.deployed()
  console.log('DiamondLoupeFacet:', diamondLoupeFacet.address)

  const ManagementFacet = await ethers.getContractFactory('ManagementFacet')
  const managementFacet = await ManagementFacet.deploy()
  await managementFacet.deployed()
  console.log('ManagementFacet:', managementFacet.address)

  // 4. Cut facets into diamond
  const diamondCut = await ethers.getContractAt('IDiamondCut', diamond.address)

  const cut = []
  const addFacet = async (facet) => {
    cut.push({
      facetAddress: facet.address,
      action: 0, // Add
      functionSelectors: getSelectors(facet),
    })
  }

  await addFacet(ownershipFacet)
  await addFacet(diamondLoupeFacet)
  await addFacet(managementFacet)

  const tx = await diamondCut.diamondCut(cut, ethers.constants.AddressZero, '0x')
  const receipt = await tx.wait()
  if (!receipt.status) throw new Error('Diamond upgrade failed')
  console.log('Diamond cut complete')

  // 5. Return addresses for downstream init
  return { diamondAddress: diamond.address }
}

if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch((e) => {
      console.error(e)
      process.exit(1)
    })
}

module.exports = { main }


