/* global ethers */
require('dotenv').config({ path: '../../../.env' })

async function main() {
  const [deployer] = await ethers.getSigners()
  console.log('Deployer:', deployer.address)

  // NOTE: Run this on each chain separately with the appropriate network selected.
  // Celo side: deploy MGRO and CeloMgroReceiver
  if (process.env.NETWORK_ROLE === 'CELO') {
    const MGRO = await ethers.getContractFactory('MGRO')
    const mgro = await MGRO.deploy(process.env.LZ_ENDPOINT, deployer.address)
    await mgro.deployed()
    console.log('MGRO:', mgro.address)

    const CeloReceiver = await ethers.getContractFactory('CeloMgroReceiver')
    const receiver = await CeloReceiver.deploy(process.env.LZ_ENDPOINT, deployer.address, mgro.address)
    await receiver.deployed()
    console.log('CeloMgroReceiver:', receiver.address)

    // make receiver management
    const tx = await mgro.setManagementContract(receiver.address)
    await tx.wait()
    console.log('MGRO management set to receiver')

    return { mgro: mgro.address, receiver: receiver.address }
  }

  // Base side: deploy BaseMgroMessenger
  if (process.env.NETWORK_ROLE === 'BASE') {
    const Messenger = await ethers.getContractFactory('BaseMgroMessenger')
    const messenger = await Messenger.deploy(process.env.LZ_ENDPOINT, deployer.address, process.env.DIAMOND_ADDRESS)
    await messenger.deployed()
    console.log('BaseMgroMessenger:', messenger.address)
    return { messenger: messenger.address }
  }

  throw new Error('Set NETWORK_ROLE to CELO or BASE')
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


