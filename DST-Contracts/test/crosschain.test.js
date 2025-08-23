const { expect } = require("chai");

describe("Cross-chain MGRO flow", function () {
  it("receiver mints and burns via _lzReceive harness", async function () {
    const [deployer, user, delegate] = await ethers.getSigners();

    // Deploy mock endpoint for OApp constructors
    const MockEndpoint = await ethers.getContractFactory("MockLzEndpointV2");
    const endpoint = await MockEndpoint.deploy();
    await endpoint.deployed();

    // Deploy MGRO
    const MGRO = await ethers.getContractFactory("MGRO");
    const mgro = await MGRO.deploy(endpoint.address, delegate.address);
    await mgro.deployed();

    // Deploy receiver harness
    const Harness = await ethers.getContractFactory("CeloMgroReceiverHarness");
    const receiver = await Harness.deploy(endpoint.address, delegate.address, mgro.address);
    await receiver.deployed();

    // Set management on MGRO to receiver (owner-only)
    await mgro.connect(deployer).setManagementContract(receiver.address);

    // Mint via harness using calldata-friendly function
    const origin = { srcEid: 1, sender: ethers.utils.hexZeroPad(receiver.address, 32), nonce: 1 };
    const mintMsg = ethers.utils.defaultAbiCoder.encode([
      "uint8",
      "address",
      "uint256",
    ], [0, user.address, ethers.utils.parseEther("100")]);
    await receiver.hReceive(origin, ethers.constants.HashZero, mintMsg, "0x");
    expect(await mgro.balanceOf(user.address)).to.equal(ethers.utils.parseEther("100"));

    const burnMsg = ethers.utils.defaultAbiCoder.encode([
      "uint8",
      "address",
      "uint256",
    ], [1, user.address, ethers.utils.parseEther("40")]);
    await receiver.hReceive(origin, ethers.constants.HashZero, burnMsg, "0x");
    expect(await mgro.balanceOf(user.address)).to.equal(ethers.utils.parseEther("60"));
  });
});


