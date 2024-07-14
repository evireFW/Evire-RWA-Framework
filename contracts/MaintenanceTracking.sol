// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./RWAAsset.sol";

/**
 * @title MaintenanceTracking
 * @dev Contract for tracking maintenance activities of Real World Assets (RWA)
 */
contract MaintenanceTracking is Ownable {
    using Counters for Counters.Counter;

    struct MaintenanceRecord {
        uint256 assetId;
        string description;
        uint256 timestamp;
        address performedBy;
        uint256 cost;
        bool isCompleted;
    }

    RWAAsset public rwaAsset;
    Counters.Counter private _maintenanceIds;
    mapping(uint256 => MaintenanceRecord) public maintenanceRecords;
    mapping(uint256 => uint256[]) public assetMaintenanceHistory;

    event MaintenanceScheduled(uint256 indexed maintenanceId, uint256 indexed assetId, string description);
    event MaintenanceCompleted(uint256 indexed maintenanceId, uint256 indexed assetId, address performedBy, uint256 cost);

    constructor(address _rwaAssetAddress) {
        rwaAsset = RWAAsset(_rwaAssetAddress);
    }

    /**
     * @dev Schedule a maintenance activity for an asset
     * @param _assetId The ID of the asset requiring maintenance
     * @param _description A description of the maintenance activity
     */
    function scheduleMaintenance(uint256 _assetId, string memory _description) external onlyOwner {
        require(rwaAsset.ownerOf(_assetId) != address(0), "Asset does not exist");

        _maintenanceIds.increment();
        uint256 newMaintenanceId = _maintenanceIds.current();

        maintenanceRecords[newMaintenanceId] = MaintenanceRecord({
            assetId: _assetId,
            description: _description,
            timestamp: block.timestamp,
            performedBy: address(0),
            cost: 0,
            isCompleted: false
        });

        assetMaintenanceHistory[_assetId].push(newMaintenanceId);

        emit MaintenanceScheduled(newMaintenanceId, _assetId, _description);
    }

    /**
     * @dev Mark a maintenance activity as completed
     * @param _maintenanceId The ID of the maintenance activity
     * @param _cost The cost of the maintenance activity
     */
    function completeMaintenance(uint256 _maintenanceId, uint256 _cost) external {
        MaintenanceRecord storage record = maintenanceRecords[_maintenanceId];
        require(!record.isCompleted, "Maintenance already completed");
        require(rwaAsset.ownerOf(record.assetId) == msg.sender, "Only asset owner can complete maintenance");

        record.isCompleted = true;
        record.performedBy = msg.sender;
        record.cost = _cost;
        record.timestamp = block.timestamp;

        emit MaintenanceCompleted(_maintenanceId, record.assetId, msg.sender, _cost);
    }

    /**
     * @dev Get the maintenance history for an asset
     * @param _assetId The ID of the asset
     * @return An array of maintenance record IDs for the asset
     */
    function getAssetMaintenanceHistory(uint256 _assetId) external view returns (uint256[] memory) {
        return assetMaintenanceHistory[_assetId];
    }

    /**
     * @dev Get details of a specific maintenance record
     * @param _maintenanceId The ID of the maintenance record
     * @return The maintenance record details
     */
    function getMaintenanceDetails(uint256 _maintenanceId) external view returns (MaintenanceRecord memory) {
        return maintenanceRecords[_maintenanceId];
    }
}