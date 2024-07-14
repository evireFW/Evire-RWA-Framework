// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title OracleIntegration
 * @dev This contract integrates with Chainlink oracles to fetch real-world data for RWA management
 */
contract OracleIntegration is Ownable {
    // Mapping to store oracle addresses for different data types
    mapping(bytes32 => address) private oracles;

    // Events
    event OracleAdded(bytes32 dataType, address oracleAddress);
    event OracleUpdated(bytes32 dataType, address oracleAddress);
    event DataRequested(bytes32 dataType, uint256 requestId);

    /**
     * @dev Add a new oracle for a specific data type
     * @param dataType The type of data this oracle provides
     * @param oracleAddress The address of the Chainlink oracle contract
     */
    function addOracle(bytes32 dataType, address oracleAddress) external onlyOwner {
        require(oracleAddress != address(0), "Invalid oracle address");
        require(oracles[dataType] == address(0), "Oracle already exists for this data type");

        oracles[dataType] = oracleAddress;
        emit OracleAdded(dataType, oracleAddress);
    }

    /**
     * @dev Update an existing oracle for a specific data type
     * @param dataType The type of data this oracle provides
     * @param newOracleAddress The new address of the Chainlink oracle contract
     */
    function updateOracle(bytes32 dataType, address newOracleAddress) external onlyOwner {
        require(newOracleAddress != address(0), "Invalid oracle address");
        require(oracles[dataType] != address(0), "Oracle does not exist for this data type");

        oracles[dataType] = newOracleAddress;
        emit OracleUpdated(dataType, newOracleAddress);
    }

    /**
     * @dev Fetch the latest data from a specific oracle
     * @param dataType The type of data to fetch
     * @return The latest data from the oracle
     */
    function getLatestData(bytes32 dataType) public view returns (int256) {
        require(oracles[dataType] != address(0), "Oracle not set for this data type");

        AggregatorV3Interface oracle = AggregatorV3Interface(oracles[dataType]);
        (
            uint80 roundID, 
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = oracle.latestRoundData();

        require(timeStamp > 0, "Round not complete");
        return price;
    }

    /**
     * @dev Request new data from a specific oracle (for oracles that support this)
     * @param dataType The type of data to request
     * @return requestId The ID of the oracle request
     */
    function requestNewData(bytes32 dataType) external returns (uint256 requestId) {
        require(oracles[dataType] != address(0), "Oracle not set for this data type");

        // Note: This is a simplified example. In a real implementation, you would
        // need to integrate with the specific oracle's request mechanism.
        // For demonstration purposes, we're just emitting an event here.
        emit DataRequested(dataType, block.timestamp);
        return block.timestamp;
    }

    /**
     * @dev Get the address of an oracle for a specific data type
     * @param dataType The type of data
     * @return The address of the oracle contract
     */
    function getOracleAddress(bytes32 dataType) external view returns (address) {
        return oracles[dataType];
    }
}