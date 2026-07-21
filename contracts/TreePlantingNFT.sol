// SPDX-License-Identifier: GPL
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/ITreePlantingNFT.sol";

/**
 * @title TreePlantingNFT
 * @author Treegens Foundation
 * @notice ERC-721 certificates for verified tree-planting submissions.
 *         Video files are hosted on Google Cloud Storage; this contract stores
 *         storage keys on-chain and points token metadata at an HTTPS JSON URL.
 */
contract TreePlantingNFT is ERC721URIStorage, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 private s_nextTokenId;

    mapping(uint256 => ITreePlantingNFT.PlantingRecord) private s_plantings;
    mapping(bytes32 => uint256) private s_submissionIdToToken;
    mapping(bytes32 => bool) private s_submissionMinted;

    event PlantingMinted(address indexed to, uint256 indexed tokenId, bytes32 indexed submissionId, string metadataUrl);

    error TreePlantingNFT__InvalidInput();
    error TreePlantingNFT__AlreadyMinted();

    constructor() ERC721("Treegens Planting", "TGPLANT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Mints a planting NFT to `to` for a verified submission.
    function mint(
        address to,
        bytes32 submissionId,
        string calldata metadataUrl,
        ITreePlantingNFT.PlantingRecord calldata data
    ) external onlyRole(MINTER_ROLE) returns (uint256 tokenId) {
        if (to == address(0)) revert TreePlantingNFT__InvalidInput();
        if (submissionId == bytes32(0)) revert TreePlantingNFT__InvalidInput();
        if (s_submissionMinted[submissionId]) revert TreePlantingNFT__AlreadyMinted();
        if (bytes(data.plantStorageKey).length == 0) revert TreePlantingNFT__InvalidInput();
        if (bytes(data.treeType).length == 0) revert TreePlantingNFT__InvalidInput();
        if (bytes(metadataUrl).length == 0) revert TreePlantingNFT__InvalidInput();
        if (data.treeCount == 0) revert TreePlantingNFT__InvalidInput();
        if (data.latitude < -90_000_000 || data.latitude > 90_000_000) {
            revert TreePlantingNFT__InvalidInput();
        }
        if (data.longitude < -180_000_000 || data.longitude > 180_000_000) {
            revert TreePlantingNFT__InvalidInput();
        }

        tokenId = s_nextTokenId;
        unchecked {
            ++s_nextTokenId;
        }

        s_submissionMinted[submissionId] = true;
        s_submissionIdToToken[submissionId] = tokenId;
        s_plantings[tokenId] = data;

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, metadataUrl);

        emit PlantingMinted(to, tokenId, submissionId, metadataUrl);
    }

    /// @notice Returns the on-chain planting record for a token.
    function getPlantingRecord(uint256 tokenId) external view returns (ITreePlantingNFT.PlantingRecord memory) {
        _requireOwned(tokenId);
        return s_plantings[tokenId];
    }

    /// @notice Returns whether a submission has already been minted.
    function isSubmissionMinted(bytes32 submissionId) external view returns (bool) {
        return s_submissionMinted[submissionId];
    }

    /// @notice Returns the token id minted for a submission, or zero if not minted.
    function submissionIdToToken(bytes32 submissionId) external view returns (uint256) {
        if (!s_submissionMinted[submissionId]) {
            return 0;
        }
        return s_submissionIdToToken[submissionId];
    }

    /// @inheritdoc ERC721URIStorage
    function tokenURI(uint256 tokenId) public view override(ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /// @inheritdoc ERC165
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721URIStorage, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
