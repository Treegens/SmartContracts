// SPDX-License-Identifier: GPL
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/ITreePlantingNFT.sol";

/**
 * @title BaseTreePlantingNFT
 * @author Treegens Foundation
 * @notice Shared ERC-721 logic for verified tree-planting video NFTs.
 *         Video files are hosted on Google Cloud Storage; this contract stores
 *         storage keys on-chain and points token metadata at an HTTPS JSON URL.
 *         Concrete contracts (e.g. {MangroveTreeNFT}, {NonMangroveTreeNFT}) set
 *         their own name/symbol and inherit minting, storage, and views from here.
 */
abstract contract BaseTreePlantingNFT is ERC721URIStorage, AccessControl, ITreePlantingNFT {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 private s_nextTokenId;

    mapping(uint256 => PlantingRecord) private s_plantings;
    mapping(bytes32 => uint256) private s_submissionIdToToken;
    mapping(bytes32 => bool) private s_submissionMinted;

    event PlantingMinted(address indexed to, uint256 indexed tokenId, bytes32 indexed submissionId, string metadataUrl);

    error BaseTreePlantingNFT__ZeroAddress();
    error BaseTreePlantingNFT__ZeroSubmissionId();
    error BaseTreePlantingNFT__AlreadyMinted();
    error BaseTreePlantingNFT__EmptyPlantStorageKey();
    error BaseTreePlantingNFT__EmptyTreeType();
    error BaseTreePlantingNFT__EmptyMetadataUrl();
    error BaseTreePlantingNFT__ZeroTreeCount();
    error BaseTreePlantingNFT__InvalidLatitude();
    error BaseTreePlantingNFT__InvalidLongitude();

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Mints a planting NFT to `to` for a verified submission.
    function mint(
        address to,
        bytes32 submissionId,
        string calldata metadataUrl,
        PlantingRecord calldata data
    ) external onlyRole(MINTER_ROLE) returns (uint256 tokenId) {
        if (to == address(0)) revert BaseTreePlantingNFT__ZeroAddress();
        if (submissionId == bytes32(0)) revert BaseTreePlantingNFT__ZeroSubmissionId();
        if (s_submissionMinted[submissionId]) revert BaseTreePlantingNFT__AlreadyMinted();
        if (bytes(data.plantStorageKey).length == 0) revert BaseTreePlantingNFT__EmptyPlantStorageKey();
        if (bytes(data.treeType).length == 0) revert BaseTreePlantingNFT__EmptyTreeType();
        if (bytes(metadataUrl).length == 0) revert BaseTreePlantingNFT__EmptyMetadataUrl();
        if (data.treeCount == 0) revert BaseTreePlantingNFT__ZeroTreeCount();
        if (data.latitude < -90_000_000 || data.latitude > 90_000_000) {
            revert BaseTreePlantingNFT__InvalidLatitude();
        }
        if (data.longitude < -180_000_000 || data.longitude > 180_000_000) {
            revert BaseTreePlantingNFT__InvalidLongitude();
        }

        unchecked {
            tokenId = ++s_nextTokenId;
        }

        s_submissionMinted[submissionId] = true;
        s_submissionIdToToken[submissionId] = tokenId;
        s_plantings[tokenId] = data;

        _setTokenURI(tokenId, metadataUrl);
        _safeMint(to, tokenId);

        emit PlantingMinted(to, tokenId, submissionId, metadataUrl);
    }

    /// @notice Returns the on-chain planting record for a token.
    function getPlantingRecord(uint256 tokenId) external view returns (PlantingRecord memory) {
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
