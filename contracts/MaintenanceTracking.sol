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
        uint256 scheduledTimestamp;
        uint256 completedTimestamp;
        address assignedTo;
        address performedBy;
        uint256 cost;
        bool isCompleted;
    }

    RWAAsset public rwaAsset;
    Counters.Counter private _maintenanceIds;
    mapping(uint256 => MaintenanceRecord) public maintenanceRecords;
    mapping(uint256 => uint256[]) public assetMaintenanceHistory;

    event MaintenanceScheduled(uint256 indexed maintenanceId, uint256 indexed assetId, string description, address assignedTo);
    event MaintenanceCompleted(uint256 indexed maintenanceId, uint256 indexed assetId, address performedBy, uint256 cost);
    event MaintenanceReassigned(uint256 indexed maintenanceId, uint256 indexed assetId, address newAssignedTo);
    event MaintenanceCanceled(uint256 indexed maintenanceId, uint256 indexed assetId);

    /**
     * @dev Constructor initializes the RWAAsset contract address
     * @param _rwaAssetAddress The address of the RWAAsset contract
     */
    constructor(address _rwaAssetAddress) {
        rwaAsset = RWAAsset(_rwaAssetAddress);
    }

    /**
     * @dev Schedule a maintenance activity for an asset
     * @param _assetId The ID of the asset requiring maintenance
     * @param _description A description of the maintenance activity
     * @param _assignedTo The address of the maintenance provider
     */
    function scheduleMaintenance(uint256 _assetId, string memory _description, address _assignedTo) external {
        require(rwaAsset.ownerOf(_assetId) == msg.sender, "Only asset owner can schedule maintenance");
        require(_assignedTo != address(0), "Invalid assignedTo address");

        _maintenanceIds.increment();
        uint256 newMaintenanceId = _maintenanceIds.current();

        maintenanceRecords[newMaintenanceId] = MaintenanceRecord({
            assetId: _assetId,
            description: _description,
            scheduledTimestamp: block.timestamp,
            completedTimestamp: 0,
            assignedTo: _assignedTo,
            performedBy: address(0),
            cost: 0,
            isCompleted: false
        });

        assetMaintenanceHistory[_assetId].push(newMaintenanceId);

        emit MaintenanceScheduled(newMaintenanceId, _assetId, _description, _assignedTo);
    }

    /**
     * @dev Mark a maintenance activity as completed
     * @param _maintenanceId The ID of the maintenance activity
     * @param _cost The cost of the maintenance activity
     */
    function completeMaintenance(uint256 _maintenanceId, uint256 _cost) external {
        MaintenanceRecord storage record = maintenanceRecords[_maintenanceId];
        require(!record.isCompleted, "Maintenance already completed");
        require(record.assignedTo == msg.sender, "Only assigned provider can complete maintenance");

        record.isCompleted = true;
        record.performedBy = msg.sender;
        record.cost = _cost;
        record.completedTimestamp = block.timestamp;

        emit MaintenanceCompleted(_maintenanceId, record.assetId, msg.sender, _cost);
    }

    /**
     * @dev Reassign a maintenance activity to a new provider
     * @param _maintenanceId The ID of the maintenance activity
     * @param _newAssignedTo The address of the new maintenance provider
     */
    function reassignMaintenance(uint256 _maintenanceId, address _newAssignedTo) external {
        MaintenanceRecord storage record = maintenanceRecords[_maintenanceId];
        require(!record.isCompleted, "Maintenance already completed");
        require(rwaAsset.ownerOf(record.assetId) == msg.sender, "Only asset owner can reassign maintenance");
        require(_newAssignedTo != address(0), "Invalid assignedTo address");

        record.assignedTo = _newAssignedTo;

        emit MaintenanceReassigned(_maintenanceId, record.assetId, _newAssignedTo);
    }

    /**
     * @dev Cancel a scheduled maintenance activity
     * @param _maintenanceId The ID of the maintenance activity
     */
    function cancelMaintenance(uint256 _maintenanceId) external {
        MaintenanceRecord storage record = maintenanceRecords[_maintenanceId];
        require(!record.isCompleted, "Maintenance already completed");
        require(rwaAsset.ownerOf(record.assetId) == msg.sender, "Only asset owner can cancel maintenance");

        // Remove from assetMaintenanceHistory
        uint256[] storage history = assetMaintenanceHistory[record.assetId];
        for (uint256 i = 0; i < history.length; i++) {
            if (history[i] == _maintenanceId) {
                history[i] = history[history.length - 1];
                history.pop();
                break;
            }
        }

        emit MaintenanceCanceled(_maintenanceId, record.assetId);

        delete maintenanceRecords[_maintenanceId];
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
