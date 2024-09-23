// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

/**
 * @title OracleIntegration
 * @dev Integrates with Chainlink oracles to fetch real-world data for RWA management
 */
contract OracleIntegration is Ownable, ChainlinkClient {
    using Chainlink for Chainlink.Request;

    enum DataType { INT256, UINT256, STRING, BYTES32 }

    struct OracleSettings {
        address oracleAddress;
        bytes32 jobId;
        uint256 fee;
        DataType dataType;
        bool exists;
    }

    mapping(bytes32 => OracleSettings) private oracles;
    mapping(bytes32 => bytes32) private requestIdToDataTypeKey;

    // Data storage
    mapping(bytes32 => int256) public latestDataInt256;
    mapping(bytes32 => uint256) public latestDataUint256;
    mapping(bytes32 => string) public latestDataString;
    mapping(bytes32 => bytes32) public latestDataBytes32;

    // Events
    event OracleAdded(bytes32 dataTypeKey, address oracleAddress);
    event OracleUpdated(bytes32 dataTypeKey, address oracleAddress);
    event OracleRemoved(bytes32 dataTypeKey);
    event DataRequested(bytes32 dataTypeKey, bytes32 requestId);
    event DataReceived(bytes32 dataTypeKey, bytes32 requestId);

    constructor() {
        setPublicChainlinkToken();
    }

    /**
     * @dev Add a new oracle for a specific data type
     */
    function addOracle(bytes32 dataTypeKey, address oracleAddress, bytes32 jobId, uint256 fee, DataType dataType) external onlyOwner {
        require(oracleAddress != address(0), "Invalid oracle address");
        require(!oracles[dataTypeKey].exists, "Oracle already exists for this data type");

        oracles[dataTypeKey] = OracleSettings({
            oracleAddress: oracleAddress,
            jobId: jobId,
            fee: fee,
            dataType: dataType,
            exists: true
        });
        emit OracleAdded(dataTypeKey, oracleAddress);
    }

    /**
     * @dev Update an existing oracle for a specific data type
     */
    function updateOracle(bytes32 dataTypeKey, address oracleAddress, bytes32 jobId, uint256 fee, DataType dataType) external onlyOwner {
        require(oracleAddress != address(0), "Invalid oracle address");
        require(oracles[dataTypeKey].exists, "Oracle does not exist for this data type");

        oracles[dataTypeKey] = OracleSettings({
            oracleAddress: oracleAddress,
            jobId: jobId,
            fee: fee,
            dataType: dataType,
            exists: true
        });
        emit OracleUpdated(dataTypeKey, oracleAddress);
    }

    /**
     * @dev Remove an oracle for a specific data type
     */
    function removeOracle(bytes32 dataTypeKey) external onlyOwner {
        require(oracles[dataTypeKey].exists, "Oracle does not exist for this data type");
        delete oracles[dataTypeKey];
        emit OracleRemoved(dataTypeKey);
    }

    /**
     * @dev Request new data from a specific oracle
     */
    function requestNewData(bytes32 dataTypeKey) external returns (bytes32 requestId) {
        require(oracles[dataTypeKey].exists, "Oracle not set for this data type");

        OracleSettings memory settings = oracles[dataTypeKey];

        Chainlink.Request memory request = buildChainlinkRequest(settings.jobId, address(this), getFulfillFunctionSelector(settings.dataType));

        requestId = sendChainlinkRequestTo(settings.oracleAddress, request, settings.fee);

        requestIdToDataTypeKey[requestId] = dataTypeKey;

        emit DataRequested(dataTypeKey, requestId);
    }

    function getFulfillFunctionSelector(DataType dataType) internal pure returns (bytes4) {
        if (dataType == DataType.INT256) {
            return this.fulfillInt256.selector;
        } else if (dataType == DataType.UINT256) {
            return this.fulfillUint256.selector;
        } else if (dataType == DataType.STRING) {
            return this.fulfillString.selector;
        } else if (dataType == DataType.BYTES32) {
            return this.fulfillBytes32.selector;
        } else {
            revert("Unsupported data type");
        }
    }

    /**
     * @dev Callback function for int256 data
     */
    function fulfillInt256(bytes32 _requestId, int256 _data) public recordChainlinkFulfillment(_requestId) {
        bytes32 dataTypeKey = requestIdToDataTypeKey[_requestId];
        latestDataInt256[dataTypeKey] = _data;
        emit DataReceived(dataTypeKey, _requestId);
    }

    /**
     * @dev Callback function for uint256 data
     */
    function fulfillUint256(bytes32 _requestId, uint256 _data) public recordChainlinkFulfillment(_requestId) {
        bytes32 dataTypeKey = requestIdToDataTypeKey[_requestId];
        latestDataUint256[dataTypeKey] = _data;
        emit DataReceived(dataTypeKey, _requestId);
    }

    /**
     * @dev Callback function for string data
     */
    function fulfillString(bytes32 _requestId, string memory _data) public recordChainlinkFulfillment(_requestId) {
        bytes32 dataTypeKey = requestIdToDataTypeKey[_requestId];
        latestDataString[dataTypeKey] = _data;
        emit DataReceived(dataTypeKey, _requestId);
    }

    /**
     * @dev Callback function for bytes32 data
     */
    function fulfillBytes32(bytes32 _requestId, bytes32 _data) public recordChainlinkFulfillment(_requestId) {
        bytes32 dataTypeKey = requestIdToDataTypeKey[_requestId];
        latestDataBytes32[dataTypeKey] = _data;
        emit DataReceived(dataTypeKey, _requestId);
    }

    /**
     * @dev Get the oracle settings for a specific data type
     */
    function getOracleSettings(bytes32 dataTypeKey) external view returns (address, bytes32, uint256, DataType) {
        OracleSettings memory settings = oracles[dataTypeKey];
        require(settings.exists, "Oracle not set for this data type");
        return (settings.oracleAddress, settings.jobId, settings.fee, settings.dataType);
    }
}