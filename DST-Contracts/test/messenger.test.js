const { expect } = require("chai");

describe("BaseMgroMessenger", function () {
  it("quotes and sends with mocked params", async function () {
    const [deployer, delegate, management, user] = await ethers.getSigners();

    const MockEndpoint = await ethers.getContractFactory("MockLzEndpointV2");
    const endpoint = await MockEndpoint.deploy();
    await endpoint.deployed();

    const Messenger = await ethers.getContractFactory("BaseMgroMessenger");
    const messenger = await Messenger.deploy(endpoint.address, delegate.address, management.address);
    await messenger.deployed();

    // set peer to avoid _getPeerOrRevert in quote/_lzSend
    await messenger.connect(deployer).setPeer(1, ethers.utils.hexZeroPad(messenger.address, 32));

    const dstEid = 1;
    const amount = ethers.utils.parseEther("1");
    const options = "0x";

    const fee = await messenger.quoteMint(dstEid, user.address, amount, options, false);
    expect(fee.nativeFee).to.equal(0);

    await expect(
      messenger.connect(management).sendMint(dstEid, user.address, amount, options, false, { value: fee.nativeFee })
    ).to.not.be.reverted;
  });
});


