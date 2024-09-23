// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./DataVerification.sol";
import "./ComplianceChecks.sol";

/**
 * @title AssetTokenization
 * @dev Library for tokenizing real-world assets (RWA) on the blockchain
 */
library AssetTokenization {
    struct Asset {
        uint256 id;
        string assetType;
        uint256 value;
        address owner;
        bool isFragmented;
        uint256 totalFragments;
        mapping(address => uint256) fragmentBalances;
    }

    struct TokenizationParams {
        string assetType;
        uint256 initialValue;
        bool isFragmented;
        uint256 totalFragments;
    }

    event AssetTokenized(uint256 indexed assetId, address indexed owner, uint256 value);
    event AssetFragmented(uint256 indexed assetId, uint256 totalFragments);
    event FragmentTransferred(uint256 indexed assetId, address indexed from, address indexed to, uint256 amount);
    event AssetValueUpdated(uint256 indexed assetId, uint256 newValue);
    event AssetOwnershipTransferred(uint256 indexed assetId, address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Tokenize a new asset
     * @param assets The mapping of asset IDs to Asset structs
     * @param params The parameters for tokenization
     * @param owner The address of the asset owner
     * @return The ID of the newly tokenized asset
     */
    function tokenizeAsset(
        mapping(uint256 => Asset) storage assets,
        TokenizationParams memory params,
        address owner
    ) internal returns (uint256) {
        require(ComplianceChecks.isVerifiedUser(owner), "Owner must be verified");
        require(DataVerification.isValidAssetType(params.assetType), "Invalid asset type");

        uint256 assetId = uint256(keccak256(abi.encodePacked(block.timestamp, owner, params.assetType)));
        require(assets[assetId].id == 0, "Asset already exists");

        Asset storage newAsset = assets[assetId];
        newAsset.id = assetId;
        newAsset.assetType = params.assetType;
        newAsset.value = params.initialValue;
        newAsset.owner = owner;
        newAsset.isFragmented = params.isFragmented;

        if (params.isFragmented) {
            require(params.totalFragments > 0, "Total fragments must be greater than zero");
            newAsset.totalFragments = params.totalFragments;
            newAsset.fragmentBalances[owner] = params.totalFragments;
            emit AssetFragmented(assetId, params.totalFragments);
        }

        emit AssetTokenized(assetId, owner, params.initialValue);

        return assetId;
    }

    /**
     * @dev Fragment an existing non-fragmented asset
     * @param assets The mapping of asset IDs to Asset structs
     * @param assetId The ID of the asset to fragment
     * @param totalFragments The total number of fragments to create
     */
    function fragmentAsset(
        mapping(uint256 => Asset) storage assets,
        uint256 assetId,
        uint256 totalFragments
    ) internal {
        Asset storage asset = assets[assetId];
        require(asset.id != 0, "Asset does not exist");
        require(asset.owner == msg.sender, "Only the asset owner can fragment the asset");
        require(!asset.isFragmented, "Asset is already fragmented");
        require(totalFragments > 0, "Total fragments must be greater than zero");

        asset.isFragmented = true;
        asset.totalFragments = totalFragments;
        asset.fragmentBalances[asset.owner] = totalFragments;

        emit AssetFragmented(assetId, totalFragments);
    }

    /**
     * @dev Transfer asset fragments from one address to another
     * @param assets The mapping of asset IDs to Asset structs
     * @param assetId The ID of the fragmented asset
     * @param from The address sending the fragments
     * @param to The address receiving the fragments
     * @param amount The number of fragments to transfer
     */
    function transferFragments(
        mapping(uint256 => Asset) storage assets,
        uint256 assetId,
        address from,
        address to,
        uint256 amount
    ) internal {
        Asset storage asset = assets[assetId];
        require(asset.id != 0, "Asset does not exist");
        require(asset.isFragmented, "Asset is not fragmented");
        require(from == msg.sender, "Caller is not the owner of the fragments");
        require(asset.fragmentBalances[from] >= amount, "Insufficient fragment balance");

        asset.fragmentBalances[from] -= amount;
        asset.fragmentBalances[to] += amount;

        emit FragmentTransferred(assetId, from, to, amount);
    }

    /**
     * @dev Update the value of an asset
     * @param assets The mapping of asset IDs to Asset structs
     * @param assetId The ID of the asset to update
     * @param newValue The new value of the asset
     */
    function updateAssetValue(
        mapping(uint256 => Asset) storage assets,
        uint256 assetId,
        uint256 newValue
    ) internal {
        Asset storage asset = assets[assetId];
        require(asset.id != 0, "Asset does not exist");
        require(asset.owner == msg.sender, "Only the asset owner can update the asset value");

        asset.value = newValue;

        emit AssetValueUpdated(assetId, newValue);
    }

    /**
     * @dev Transfer ownership of an asset
     * @param assets The mapping of asset IDs to Asset structs
     * @param assetId The ID of the asset to transfer
     * @param newOwner The address of the new owner
     */
    function transferAssetOwnership(
        mapping(uint256 => Asset) storage assets,
        uint256 assetId,
        address newOwner
    ) internal {
        Asset storage asset = assets[assetId];
        require(asset.id != 0, "Asset does not exist");
        require(asset.owner == msg.sender, "Only the asset owner can transfer ownership");
        require(ComplianceChecks.isVerifiedUser(newOwner), "New owner must be verified");

        address previousOwner = asset.owner;
        asset.owner = newOwner;

        emit AssetOwnershipTransferred(assetId, previousOwner, newOwner);
    }

    /**
     * @dev Get the fragment balance of an address for a specific asset
     * @param assets The mapping of asset IDs to Asset structs
     * @param assetId The ID of the fragmented asset
     * @param account The address to check the balance for
     * @return The fragment balance of the account
     */
    function getFragmentBalance(
        mapping(uint256 => Asset) storage assets,
        uint256 assetId,
        address account
    ) internal view returns (uint256) {
        Asset storage asset = assets[assetId];
        require(asset.id != 0, "Asset does not exist");
        require(asset.isFragmented, "Asset is not fragmented");
        return asset.fragmentBalances[account];
    }

    /**
     * @dev Calculate the value of fragments for a given asset
     * @param assets The mapping of asset IDs to Asset structs
     * @param assetId The ID of the fragmented asset
     * @param fragmentCount The number of fragments to calculate the value for
     * @return The value of the specified number of fragments
     */
    function calculateFragmentValue(
        mapping(uint256 => Asset) storage assets,
        uint256 assetId,
        uint256 fragmentCount
    ) internal view returns (uint256) {
        Asset storage asset = assets[assetId];
        require(asset.id != 0, "Asset does not exist");
        require(asset.isFragmented, "Asset is not fragmented");
        require(fragmentCount > 0, "Fragment count must be greater than zero");
        require(fragmentCount <= asset.totalFragments, "Fragment count exceeds total fragments");

        return (asset.value * fragmentCount) / asset.totalFragments;
    }

    /**
     * @dev Check if an address is the owner of an asset
     * @param assets The mapping of asset IDs to Asset structs
     * @param assetId The ID of the asset to check
     * @param account The address to check ownership for
     * @return True if the account is the owner, false otherwise
     */
    function isAssetOwner(
        mapping(uint256 => Asset) storage assets,
        uint256 assetId,
        address account
    ) internal view returns (bool) {
        Asset storage asset = assets[assetId];
        require(asset.id != 0, "Asset does not exist");
        return asset.owner == account;
    }
}
