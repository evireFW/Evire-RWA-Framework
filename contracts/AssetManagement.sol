// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./RWAAsset.sol";
import "./Compliance.sol";
import "../libraries/AssetValuation.sol";
import "../libraries/OwnershipTransfer.sol";

contract AssetManagement is ERC721, Ownable {
    using Counters for Counters.Counter;
    using AssetValuation for uint256;
    using OwnershipTransfer for address;

    Counters.Counter private _tokenIds;
    Compliance private _compliance;

    struct Asset {
        string assetType;
        uint256 value;
        string metadata;
        bool isActive;
    }

    mapping(uint256 => Asset) private _assets;

    event AssetCreated(uint256 indexed tokenId, string assetType, uint256 value);
    event AssetUpdated(uint256 indexed tokenId, uint256 newValue);
    event AssetDeactivated(uint256 indexed tokenId);

    constructor(address complianceAddress) ERC721("RWA Asset", "RWAA") {
        _compliance = Compliance(complianceAddress);
    }

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

    function updateAssetValue(uint256 tokenId, uint256 newValue) public onlyOwner {
        require(_exists(tokenId), "Asset does not exist");
        require(_assets[tokenId].isActive, "Asset is not active");

        _assets[tokenId].value = newValue;

        emit AssetUpdated(tokenId, newValue);
    }

    function deactivateAsset(uint256 tokenId) public onlyOwner {
        require(_exists(tokenId), "Asset does not exist");
        require(_assets[tokenId].isActive, "Asset is already inactive");

        _assets[tokenId].isActive = false;

        emit AssetDeactivated(tokenId);
    }

    function getAssetDetails(uint256 tokenId) public view returns (Asset memory) {
        require(_exists(tokenId), "Asset does not exist");
        return _assets[tokenId];
    }

    function transferAsset(address from, address to, uint256 tokenId) public {
        require(_compliance.isCompliant(to), "Recipient is not compliant");
        require(_assets[tokenId].isActive, "Asset is not active");

        to.transferOwnership(from, tokenId);
        _transfer(from, to, tokenId);
    }

    function getAssetValue(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Asset does not exist");
        return _assets[tokenId].value.getCurrentValue();
    }

    // Override transfer function to ensure compliance
    function _transfer(address from, address to, uint256 tokenId) internal override {
        require(_compliance.isCompliant(to), "Recipient is not compliant");
        super._transfer(from, to, tokenId);
    }
}