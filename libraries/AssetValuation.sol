// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title AssetValuation
 * @dev A library for advanced real-world asset valuation on the blockchain
 */
library AssetValuation {
    struct AssetData {
        uint256 purchasePrice;
        uint256 lastValuation;
        uint256 lastValuationTimestamp;
        string assetType;
        uint256 depreciationRate; // in percentage points
        address oracleAddress;
    }

    // Events
    event AssetValued(uint256 indexed assetId, uint256 newValue, string method);
    event DepreciationRateUpdated(uint256 indexed assetId, uint256 newRate);
    event OracleAddressUpdated(uint256 indexed assetId, address newOracleAddress);

    // Errors
    error InvalidAssetType();
    error InvalidOracleAddress();
    error InvalidDepreciationRate();
    error StaleOracleData();
    error InvalidOracleData();

    /**
     * @dev Calculate the current value of an asset using various methods
     * @param assetId The unique identifier of the asset
     * @param asset The AssetData struct containing asset information
     * @return The calculated current value of the asset
     */
    function calculateAssetValue(uint256 assetId, AssetData storage asset) internal returns (uint256) {
        bytes32 assetTypeHash = keccak256(abi.encodePacked(asset.assetType));

        if (assetTypeHash == keccak256("real_estate")) {
            return _calculateRealEstateValue(assetId, asset);
        } else if (assetTypeHash == keccak256("vehicle")) {
            return _calculateVehicleValue(assetId, asset);
        } else if (assetTypeHash == keccak256("artwork")) {
            return _calculateArtworkValue(assetId, asset);
        } else {
            revert InvalidAssetType();
        }
    }

    /**
     * @dev Calculate the value of a real estate asset
     * @param assetId The unique identifier of the asset
     * @param asset The AssetData struct containing asset information
     * @return The calculated current value of the real estate asset
     */
    function _calculateRealEstateValue(uint256 assetId, AssetData storage asset) private returns (uint256) {
        if (asset.oracleAddress == address(0)) revert InvalidOracleAddress();

        (, int256 priceIndex, , uint256 updatedAt, ) = AggregatorV3Interface(asset.oracleAddress).latestRoundData();
        if (priceIndex <= 0) revert InvalidOracleData();
        if (updatedAt < block.timestamp - 1 days) revert StaleOracleData();

        uint256 newValue = asset.lastValuation * uint256(priceIndex) / 1e8; // Assuming 8 decimals
        newValue = newValue * 105 / 100; // 5% location premium

        asset.lastValuation = newValue;
        asset.lastValuationTimestamp = block.timestamp;

        emit AssetValued(assetId, newValue, "real_estate");
        return newValue;
    }

    /**
     * @dev Calculate the value of a vehicle asset
     * @param assetId The unique identifier of the asset
     * @param asset The AssetData struct containing asset information
     * @return The calculated current value of the vehicle asset
     */
    function _calculateVehicleValue(uint256 assetId, AssetData storage asset) private returns (uint256) {
        if (asset.depreciationRate > 100) revert InvalidDepreciationRate();
        if (asset.oracleAddress == address(0)) revert InvalidOracleAddress();

        uint256 yearsElapsed = (block.timestamp - asset.lastValuationTimestamp) / 365 days;
        uint256 newValue = asset.lastValuation;

        for (uint256 i = 0; i < yearsElapsed; i++) {
            newValue = newValue * (100 - asset.depreciationRate) / 100;
        }

        (, int256 priceIndex, , uint256 updatedAt, ) = AggregatorV3Interface(asset.oracleAddress).latestRoundData();
        if (priceIndex <= 0) revert InvalidOracleData();
        if (updatedAt < block.timestamp - 1 days) revert StaleOracleData();

        newValue = newValue * uint256(priceIndex) / 1e8; // Assuming 8 decimals

        asset.lastValuation = newValue;
        asset.lastValuationTimestamp = block.timestamp;

        emit AssetValued(assetId, newValue, "vehicle");
        return newValue;
    }

    /**
     * @dev Calculate the value of an artwork asset
     * @param assetId The unique identifier of the asset
     * @param asset The AssetData struct containing asset information
     * @return The calculated current value of the artwork asset
     */
    function _calculateArtworkValue(uint256 assetId, AssetData storage asset) private returns (uint256) {
        if (asset.oracleAddress == address(0)) revert InvalidOracleAddress();

        (, int256 artMarketIndex, , uint256 updatedAt, ) = AggregatorV3Interface(asset.oracleAddress).latestRoundData();
        if (artMarketIndex <= 0) revert InvalidOracleData();
        if (updatedAt < block.timestamp - 7 days) revert StaleOracleData();

        uint256 yearsElapsed = (block.timestamp - asset.lastValuationTimestamp) / 365 days;
        uint256 newValue = asset.lastValuation;

        for (uint256 i = 0; i < yearsElapsed; i++) {
            newValue = newValue * uint256(artMarketIndex) / 1e8; // Assuming 8 decimals
        }

        newValue = newValue * 110 / 100; // 10% rarity premium

        asset.lastValuation = newValue;
        asset.lastValuationTimestamp = block.timestamp;

        emit AssetValued(assetId, newValue, "artwork");
        return newValue;
    }

    /**
     * @dev Update the depreciation rate for an asset
     * @param assetId The unique identifier of the asset
     * @param asset The AssetData struct containing asset information
     * @param newDepreciationRate The new depreciation rate to set
     */
    function updateDepreciationRate(uint256 assetId, AssetData storage asset, uint256 newDepreciationRate) internal {
        if (newDepreciationRate > 100) revert InvalidDepreciationRate();
        asset.depreciationRate = newDepreciationRate;
        emit DepreciationRateUpdated(assetId, newDepreciationRate);
    }

    /**
     * @dev Update the oracle address for an asset
     * @param assetId The unique identifier of the asset
     * @param asset The AssetData struct containing asset information
     * @param newOracleAddress The new oracle address to set
     */
    function updateOracleAddress(uint256 assetId, AssetData storage asset, address newOracleAddress) internal {
        if (newOracleAddress == address(0)) revert InvalidOracleAddress();
        asset.oracleAddress = newOracleAddress;
        emit OracleAddressUpdated(assetId, newOracleAddress);
    }
}
