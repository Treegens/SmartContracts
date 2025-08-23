/* global ethers */
require('dotenv').config({ path: '../../../.env' })

async function main() {
  const diamondAddress = process.env.DIAMOND_ADDRESS
  if (!diamondAddress) throw new Error('Set DIAMOND_ADDRESS in .env')

  const mgro = process.env.MGRO_ADDRESS
  const minter = process.env.NFT_MINTER_ADDRESS
  const dao = process.env.DAO_ADDRESS
  const buyToken = process.env.BUY_TOKEN_ADDRESS
  const price = process.env.NFT_PRICE || '0'

  const management = await ethers.getContractAt('ManagementFacet', diamondAddress)

  // initialize core addresses
  const tx1 = await management.initialize(minter, mgro, dao, buyToken)
  await tx1.wait()
  console.log('Management initialized')

  // optional price setup
  if (price !== '0') {
    const tx2 = await management.setPurchaseToken(buyToken, price)
    await tx2.wait()
    console.log('Purchase token configured')
  }

  // base URIs
  const base0 = process.env.BASE_URI_0
  const base1 = process.env.BASE_URI_1
  const base2 = process.env.BASE_URI_2
  for (const b of [base0, base1, base2]) {
    if (b) {
      const tx = await management.addBaseURI(b)
      await tx.wait()
      console.log('Added base URI:', b)
    }
  }
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


