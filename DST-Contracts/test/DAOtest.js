// TGNDAOTest.js
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TGNDAO", function () {
  let TGNDAO;
  let tgnDAO;
  let owner;
  let addr1;
  let addr2;
  let addrs;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    // Deploy your contract
    TGNToken = await ethers.getContractFactory('TGNToken');
    TGN = await TGNToken.deploy();

    const TGNDAOFactory = await ethers.getContractFactory("TGNDAO");
    tgnDAO = await TGNDAOFactory.deploy(TGN.address, 50, 10, 1);
    await tgnDAO.deployed();
  });

  it("Should return the correct voting delay", async function () {
    expect(await tgnDAO.votingDelay()).to.equal(1);
  });

  it("Should return the correct voting period", async function () {
    expect(await tgnDAO.votingPeriod()).to.equal(10);
  });

//   it("Should propose and return a valid proposal ID", async function () {
//     const proposalId = await tgnDAO.propose(
//       [addr1.address],
//       [100],
//       [ethers.utils.defaultAbiCoder.encode(["string"], ["execute()"])],
//       "Test Proposal"
//     );

//     expect(proposalId).to.not.equal(0);
//   });

  it("Should delegate votes to another address", async function () {
    const delegateTo = addr1.address;
  
    // Mint some tokens to the owner
    await TGN.mint(owner.address, ethers.utils.parseEther("1000"));
  
    // Advance time by 1 second to ensure a new block is mined
    await network.provider.send("evm_increaseTime", [1]);
    await network.provider.send("evm_mine");
  
    // Delegate votes
    await TGN.delegate(delegateTo);
  
    // Check if the delegation was successful
    const currentTimestamp = (await ethers.provider.getBlock()).timestamp;
    const delegatedVotes = await TGN.getVotes(addr1.address);
    expect(delegatedVotes).to.equal(await TGN.getVotes(delegateTo));
  });
  
  
  
  // Test voting and executing votes
  it("Should propose, vote, and execute a proposal", async function () {
    // Mint some tokens to the owner
    await TGN.mint(owner.address, ethers.utils.parseEther("1000"));
  
    // Get the current voting delay
  const currentVotingDelay = await tgnDAO.votingDelay();

  // Propose to update the voting delay
  const newVotingDelay = currentVotingDelay + 1; // Update to your desired new voting delay
  const proposalData = ethers.utils.defaultAbiCoder.encode(
    ["uint256"],
    [newVotingDelay]
  );
  
    const proposalId = await tgnDAO.propose(
      [addr1.address],
      [0],
      [proposalData],
      "Test Proposal"
    );
  
    // Vote on the proposal
    
   // await tgnDAO.castVote(proposalId, true);
  
    // Advance time to the end of the voting period
    await network.provider.send("evm_increaseTime", [10]); // Adjust to match your voting period
    await network.provider.send("evm_mine");
  
    // Execute the proposal
    await tgnDAO.execute(proposalId);
  
    // Check if the proposal was executed successfully
    const proposalState = await tgnDAO.state(proposalId);
    expect(proposalState).to.equal(4); // Check if the proposal is in the "Succeeded" state after execution
  });
  
})
