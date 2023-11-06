// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TGNVault is Ownable {
    IERC20 public tgnToken; // The TGN Token contract
    uint256 public releaseDate; // The date when tokens can be claimed (15th January 2024)

    struct Contributor {
        uint256 allocatedTokens;
        bool hasClaimed;
    }

    mapping(address => Contributor) public contributors;

    event TokensAllocated(address indexed contributor, uint256 amount);
    event TokensClaimed(address indexed contributor, uint256 amount);

    constructor(address _tgnToken) Ownable(msg.sender) {
        tgnToken = IERC20(_tgnToken);
        releaseDate = 1682241600; // Approximate timestamp for 15th January 2024
    }

    function allocateTokens(address[] calldata _contributors, uint256[] calldata _tokenAmounts) external onlyOwner {
        require(_contributors.length == _tokenAmounts.length, "Arrays length mismatch");
        for (uint256 i = 0; i < _contributors.length; i++) {
            address contributor = _contributors[i];
            uint256 tokenAmount = _tokenAmounts[i];
            require(contributor != address(0), "Invalid contributor address");
            require(!contributors[contributor].hasClaimed, "Tokens already claimed for this contributor");
            contributors[contributor].allocatedTokens += tokenAmount;
            emit TokensAllocated(contributor, tokenAmount);
        }
    }

    function claimTokens() external {
        require(block.timestamp >= releaseDate, "Tokens can't be claimed yet");
        require(contributors[msg.sender].allocatedTokens > 0, "No tokens allocated to this address");
        require(!contributors[msg.sender].hasClaimed, "Tokens already claimed for this address");

        uint256 tokenAmount = contributors[msg.sender].allocatedTokens;
        contributors[msg.sender].hasClaimed = true;
        tgnToken.transfer(msg.sender, tokenAmount);

        emit TokensClaimed(msg.sender, tokenAmount);
    }

    // Owner can change the release date if necessary
    function setReleaseDate(uint256 _newReleaseDate) external onlyOwner {
        releaseDate = _newReleaseDate;
    }
}
