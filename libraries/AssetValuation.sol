// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title AssetValuation
 * @dev A library for advanced real-world asset valuation on the blockchain
 */
library AssetValuation {
    using SafeMath for uint256;

    struct AssetData {
        uint256 purchasePrice;
        uint256 lastValuation;
        uint256 lastValuationTimestamp;
        string assetType;
        uint256 depreciationRate;
        address oracleAddress;
    }

    // Events
    event AssetValued(uint256 indexed assetId, uint256 newValue, string method);
    event DepreciationRateUpdated(uint256 indexed assetId, uint256 newRate);
    event OracleAddressUpdated(uint256 indexed assetId, address newOracleAddress);

    // Errors
    error InvalidAssetType();
    error InvalidOracleAddress();
    error StaleOracleData();

    /**
     * @dev Calculate the current value of an asset using various methods
     * @param asset The AssetData struct containing asset information
     * @return The calculated current value of the asset
     */
    function calculateAssetValue(AssetData storage asset) internal returns (uint256) {
        if (keccak256(abi.encodePacked(asset.assetType)) == keccak256(abi.encodePacked("real_estate"))) {
            return _calculateRealEstateValue(asset);
        } else if (keccak256(abi.encodePacked(asset.assetType)) == keccak256(abi.encodePacked("vehicle"))) {
            return _calculateVehicleValue(asset);
        } else if (keccak256(abi.encodePacked(asset.assetType)) == keccak256(abi.encodePacked("artwork"))) {
            return _calculateArtworkValue(asset);
        } else {
            revert InvalidAssetType();
        }
    }

    /**
     * @dev Calculate the value of a real estate asset
     * @param asset The AssetData struct containing asset information
     * @return The calculated current value of the real estate asset
     */
    function _calculateRealEstateValue(AssetData storage asset) private returns (uint256) {
        // Fetch the latest real estate price index from Chainlink oracle
        (, int256 priceIndex, , uint256 updatedAt, ) = AggregatorV3Interface(asset.oracleAddress).latestRoundData();
        
        if (updatedAt < block.timestamp.sub(1 days)) {
            revert StaleOracleData();
        }

        uint256 timeSinceLastValuation = block.timestamp.sub(asset.lastValuationTimestamp);
        uint256 appreciationFactor = uint256(priceIndex).mul(1e10).div(asset.lastValuation);
        
        uint256 newValue = asset.lastValuation.mul(appreciationFactor).div(1e10);
        
        // Apply location-based adjustment (simplified)
        newValue = newValue.mul(105).div(100);  // Assuming 5% location premium

        asset.lastValuation = newValue;
        asset.lastValuationTimestamp = block.timestamp;

        emit AssetValued(uint256(uint160(address(asset))), newValue, "real_estate");
        
        return newValue;
    }

    /**
     * @dev Calculate the value of a vehicle asset
     * @param asset The AssetData struct containing asset information
     * @return The calculated current value of the vehicle asset
     */
    function _calculateVehicleValue(AssetData storage asset) private returns (uint256) {
        uint256 timeSinceLastValuation = block.timestamp.sub(asset.lastValuationTimestamp);
        uint256 yearsSinceLastValuation = timeSinceLastValuation.div(365 days);
        
        uint256 newValue = asset.lastValuation;
        
        for (uint256 i = 0; i < yearsSinceLastValuation; i++) {
            newValue = newValue.mul(uint256(100).sub(asset.depreciationRate)).div(100);
        }
        
        // Fetch the latest used car price index from Chainlink oracle
        (, int256 priceIndex, , uint256 updatedAt, ) = AggregatorV3Interface(asset.oracleAddress).latestRoundData();
        
        if (updatedAt < block.timestamp.sub(1 days)) {
            revert StaleOracleData();
        }

        uint256 marketAdjustment = uint256(priceIndex).mul(1e10).div(10000);  // Assuming oracle returns percentage change
        newValue = newValue.mul(marketAdjustment).div(1e10);

        asset.lastValuation = newValue;
        asset.lastValuationTimestamp = block.timestamp;

        emit AssetValued(uint256(uint160(address(asset))), newValue, "vehicle");
        
        return newValue;
    }

    /**
     * @dev Calculate the value of an artwork asset
     * @param asset The AssetData struct containing asset information
     * @return The calculated current value of the artwork asset
     */
    function _calculateArtworkValue(AssetData storage asset) private returns (uint256) {
        // Fetch the latest art market index from Chainlink oracle
        (, int256 artMarketIndex, , uint256 updatedAt, ) = AggregatorV3Interface(asset.oracleAddress).latestRoundData();
        
        if (updatedAt < block.timestamp.sub(7 days)) {
            revert StaleOracleData();
        }

        uint256 timeSinceLastValuation = block.timestamp.sub(asset.lastValuationTimestamp);
        uint256 yearsSinceLastValuation = timeSinceLastValuation.div(365 days);
        
        uint256 newValue = asset.lastValuation;
        uint256 artMarketGrowth = uint256(artMarketIndex).mul(1e10).div(10000);  // Assuming oracle returns percentage change

        newValue = newValue.mul(artMarketGrowth.pow(yearsSinceLastValuation)).div(1e10 ** yearsSinceLastValuation);
        
        // Apply a rarity factor (simplified)
        newValue = newValue.mul(110).div(100);  // Assuming 10% rarity premium

        asset.lastValuation = newValue;
        asset.lastValuationTimestamp = block.timestamp;

        emit AssetValued(uint256(uint160(address(asset))), newValue, "artwork");
        
        return newValue;
    }

    /**
     * @dev Update the depreciation rate for an asset
     * @param asset The AssetData struct containing asset information
     * @param newDepreciationRate The new depreciation rate to set
     */
    function updateDepreciationRate(AssetData storage asset, uint256 newDepreciationRate) internal {
        require(newDepreciationRate <= 100, "Depreciation rate must be between 0 and 100");
        asset.depreciationRate = newDepreciationRate;
        emit DepreciationRateUpdated(uint256(uint160(address(asset))), newDepreciationRate);
    }

    /**
     * @dev Update the oracle address for an asset
     * @param asset The AssetData struct containing asset information
     * @param newOracleAddress The new oracle address to set
     */
    function updateOracleAddress(AssetData storage asset, address newOracleAddress) internal {
        if (newOracleAddress == address(0)) {
            revert InvalidOracleAddress();
        }
        asset.oracleAddress = newOracleAddress;
        emit OracleAddressUpdated(uint256(uint160(address(asset))), newOracleAddress);
    }
}