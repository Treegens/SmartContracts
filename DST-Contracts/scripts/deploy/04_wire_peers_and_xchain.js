/* global ethers */
require('dotenv').config({ path: '../../../.env' })

async function main() {
  const role = process.env.NETWORK_ROLE
  if (!role) throw new Error('Set NETWORK_ROLE')

  const messengerAddr = process.env.BASE_MESSENGER_ADDRESS
  const receiverAddr = process.env.CELO_RECEIVER_ADDRESS
  const baseEid = parseInt(process.env.BASE_EID || '0')
  const celoEid = parseInt(process.env.CELO_EID || '0')

  if (role === 'BASE') {
    const messenger = await ethers.getContractAt('BaseMgroMessenger', messengerAddr)
    // set peer: Celo receiver on Celo EID
    const tx1 = await messenger.setPeer(celoEid, ethers.utils.hexZeroPad(receiverAddr, 32))
    await tx1.wait()
    console.log('Base messenger peer set')

    // point management facet to messenger and dst eid
    const diamond = process.env.DIAMOND_ADDRESS
    const mgmt = await ethers.getContractAt('ManagementFacet', diamond)
    await (await mgmt.xchainSetMessenger(messengerAddr)).wait()
    await (await mgmt.xchainSetDstEid(celoEid)).wait()
    if (process.env.LZ_OPTIONS) {
      await (await mgmt.xchainSetOptions(process.env.LZ_OPTIONS)).wait()
    }
    console.log('ManagementFacet xchain configured')
    return
  }

  if (role === 'CELO') {
    const receiver = await ethers.getContractAt('CeloMgroReceiver', receiverAddr)
    const tx = await receiver.setPeer(baseEid, ethers.utils.hexZeroPad(messengerAddr, 32))
    await tx.wait()
    console.log('Celo receiver peer set')
    return
  }

  throw new Error('Unknown NETWORK_ROLE')
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


