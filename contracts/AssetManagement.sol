// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Compliance.sol";
import "../libraries/AssetValuation.sol";

contract AssetManagement is ERC721, Ownable {
    using Counters for Counters.Counter;
    using AssetValuation for uint256;

    Counters.Counter private _tokenIds;
    Compliance private _compliance;

    struct Asset {
        string assetType;
        uint256 value;
        string metadata; // Consider changing to a URI or hash if metadata is large
        bool isActive;
    }

    mapping(uint256 => Asset) private _assets;

    event AssetCreated(uint256 indexed tokenId, string assetType, uint256 value);
    event AssetUpdated(uint256 indexed tokenId, uint256 newValue);
    event AssetDeactivated(uint256 indexed tokenId);

    constructor(address complianceAddress) ERC721("RWA Asset", "RWAA") {
        _compliance = Compliance(complianceAddress);
    }

    /**
     * @dev Creates a new asset token and assigns it to `to`.
     * Can only be called by the contract owner.
     */
    function createAsset(
        address to,
        string memory assetType,
        uint256 initialValue,
        string memory metadata
    ) public onlyOwner returns (uint256) {
        require(_compliance.isCompliant(to), "Recipient is not compliant");

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(to, newTokenId);
        _assets[newTokenId] = Asset(assetType, initialValue, metadata, true);

        emit AssetCreated(newTokenId, assetType, initialValue);

        return newTokenId;
    }

    /**
     * @dev Updates the value of an existing asset.
     * Can only be called by the contract owner.
     */
    function updateAssetValue(uint256 tokenId, uint256 newValue) public onlyOwner {
        require(_exists(tokenId), "Asset does not exist");
        require(_assets[tokenId].isActive, "Asset is not active");

        _assets[tokenId].value = newValue;

        emit AssetUpdated(tokenId, newValue);
    }

    /**
     * @dev Deactivates an asset, preventing it from being transferred.
     * Can only be called by the contract owner.
     */
    function deactivateAsset(uint256 tokenId) public onlyOwner {
        require(_exists(tokenId), "Asset does not exist");
        require(_assets[tokenId].isActive, "Asset is already inactive");

        _assets[tokenId].isActive = false;

        emit AssetDeactivated(tokenId);
    }

    /**
     * @dev Returns the details of an asset.
     */
    function getAssetDetails(uint256 tokenId) public view returns (Asset memory) {
        require(_exists(tokenId), "Asset does not exist");
        return _assets[tokenId];
    }

    /**
     * @dev Returns the current value of an asset, possibly adjusted by AssetValuation library.
     */
    function getAssetValue(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Asset does not exist");
        return _assets[tokenId].value.getCurrentValue();
    }

    /**
     * @dev Override _beforeTokenTransfer to include compliance and asset activity checks.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        // Skip checks for minting and burning
        if (from != address(0) && to != address(0)) {
            require(_compliance.isCompliant(to), "Recipient is not compliant");
            require(_assets[tokenId].isActive, "Asset is not active");
        }
    }

    /**
     * @dev Transfers an asset token to another address.
     * Ensures the caller is the owner or approved.
     */
    function transferAsset(address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");
        safeTransferFrom(_msgSender(), to, tokenId);
    }
}
