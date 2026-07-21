// SPDX-License-Identifier: GPL
pragma solidity 0.8.28;

import "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * @title ITreePlantingNFT
 * @notice External interface for verified tree-planting video NFTs.
 * @dev ERC-721 transfer and approval methods are inherited from the underlying
 *      {IERC721} implementation. This interface documents role-gated minting
 *      and planting-specific views.
 *
 * Access is managed through {IAccessControl}. The TreePlantingNFT implementation defines:
 * - `MINTER_ROLE` — required to call {mint}
 * - `DEFAULT_ADMIN_ROLE` — grants and revokes the roles above
 *
 * Video assets are stored in Google Cloud Storage. On-chain fields reference object keys;
 * full HTTPS playback URLs live in the off-chain metadata JSON pointed to by `tokenURI`.
 */
interface ITreePlantingNFT is IAccessControl {
    /// @notice On-chain planting data mirrored from a verified submission.
    struct PlantingRecord {
        string plantStorageKey;
        string landStorageKey;
        string treeType;
        int32 latitude;
        int32 longitude;
        uint32 treeCount;
        uint64 verifiedAt;
    }

    /**
     * @notice Mints a planting NFT to `to` for a verified submission.
     * @param to Recipient of the newly minted token.
     * @param submissionId Unique submission identifier (e.g. keccak256 of backend submission id).
     * @param metadataUrl HTTPS URL to the ERC-721 metadata JSON (includes public video URLs).
     * @param data On-chain planting record with GCS storage keys and verification details.
     * @return tokenId The id of the newly minted token.
     *
     * Requirements:
     * - Caller must have `MINTER_ROLE`.
     * - `to` must not be the zero address.
     * - `submissionId` must not have been minted before.
     * - `data.plantStorageKey`, `data.treeType`, and `metadataUrl` must be non-empty.
     * - `data.treeCount` must be greater than zero.
     */
    function mint(
        address to,
        bytes32 submissionId,
        string calldata metadataUrl,
        PlantingRecord calldata data
    ) external returns (uint256 tokenId);

    /**
     * @notice Returns the on-chain planting record for a token.
     * @param tokenId ERC-721 token id.
     */
    function getPlantingRecord(uint256 tokenId) external view returns (PlantingRecord memory);

    /**
     * @notice Returns whether a submission has already been minted.
     * @param submissionId Submission identifier used at mint time.
     */
    function isSubmissionMinted(bytes32 submissionId) external view returns (bool);

    /**
     * @notice Returns the token id minted for a submission, or zero if not minted.
     * @param submissionId Submission identifier used at mint time.
     */
    function submissionIdToToken(bytes32 submissionId) external view returns (uint256);
}
