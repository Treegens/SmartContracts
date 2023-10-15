/* global describe it before ethers */

const {
  getSelectors,
  FacetCutAction,
  removeSelectors,
  findAddressPositionInFacets
} = require('../scripts/libraries/diamond.js')

const { deployDiamond } = require('../scripts/deploy.js')


const { assert, expect } = require('chai')

describe('DiamondTest', async function () {
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
    
    diamondAddress = await deployDiamond()
    diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
    diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress)
    ownershipFacet = await ethers.getContractAt('OwnershipFacet', diamondAddress)
    managementFacet = await ethers.getContractAt('ManagementFacet', diamondAddress)
  })

  it('should have 4 facets -- call to facetAddresses function', async () => {
    for (const address of await diamondLoupeFacet.facetAddresses()) {
      addresses.push(address)
    }

    assert.equal(addresses.length, 4)
  })

  it('facets should have the right function selectors -- call to facetFunctionSelectors function', async () => {
    let selectors = getSelectors(diamondCutFacet)
    result = await diamondLoupeFacet.facetFunctionSelectors(addresses[0])
    assert.sameMembers(result, selectors)
    selectors = getSelectors(diamondLoupeFacet)
    result = await diamondLoupeFacet.facetFunctionSelectors(addresses[1])
    assert.sameMembers(result, selectors)
    selectors = getSelectors(ownershipFacet)
    result = await diamondLoupeFacet.facetFunctionSelectors(addresses[2])
    assert.sameMembers(result, selectors)

  })

  it('selectors should be associated to facets correctly -- multiple calls to facetAddress function', async () => {
    assert.equal(
      addresses[0],
      await diamondLoupeFacet.facetAddress('0x1f931c1c')
    )
    assert.equal(
      addresses[1],
      await diamondLoupeFacet.facetAddress('0xcdffacc6')
    )
    assert.equal(
      addresses[1],
      await diamondLoupeFacet.facetAddress('0x01ffc9a7')
    )
    assert.equal(
      addresses[2],
      await diamondLoupeFacet.facetAddress('0xf2fde38b')
    )
  })

  

  it('should test minted call', async () => {
    const amt = 1000
    await managementFacet.updateMinted('0x11ec36418bE9a610904D1409EF0577b645104881', amt)
    const [minted, burnt] = await managementFacet.getTreeStats('0x11ec36418bE9a610904D1409EF0577b645104881')

    mintedDecimal = minted.parseInt() 
    burntDecimal = burnt.parseInt()
    expect(mintedDecimal,burntDecimal).to.equal([1000, 0 ])
  })

it('should test burnt call', async () => {
    const amt = 1000
    await managementFacet.updateBurnt('0x11ec36418bE9a610904D1409EF0577b645104881', amt)

    expect(await managementFacet.getTreeStats('0x11ec36418bE9a610904D1409EF0577b645104881')).to.equal([0, 1000 ])
  })
})

