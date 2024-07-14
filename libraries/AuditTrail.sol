// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title AuditTrail
 * @dev A library for creating and managing audit trails for Real World Assets (RWA) on the blockchain.
 */
library AuditTrail {
    using Counters for Counters.Counter;

    struct AuditEntry {
        uint256 id;
        address actor;
        bytes32 action;
        bytes32 assetId;
        uint256 timestamp;
        bytes additionalData;
    }

    struct AuditTrailStorage {
        mapping(uint256 => AuditEntry) entries;
        Counters.Counter entryCount;
        mapping(bytes32 => bool) validActions;
        mapping(address => bool) authorizedAuditors;
    }

    event AuditEntryAdded(uint256 indexed id, address indexed actor, bytes32 indexed action, bytes32 assetId);
    event AuditorAuthorized(address indexed auditor);
    event AuditorDeauthorized(address indexed auditor);
    event ActionAdded(bytes32 indexed action);
    event ActionRemoved(bytes32 indexed action);

    /**
     * @dev Adds a new audit entry to the trail.
     * @param self The storage struct for the audit trail.
     * @param actor The address performing the action.
     * @param action The action being performed.
     * @param assetId The identifier of the asset involved.
     * @param additionalData Any additional data to be stored with the entry.
     */
    function addEntry(
        AuditTrailStorage storage self,
        address actor,
        bytes32 action,
        bytes32 assetId,
        bytes memory additionalData
    ) internal {
        require(self.validActions[action], "AuditTrail: Invalid action");
        require(self.authorizedAuditors[msg.sender], "AuditTrail: Caller is not an authorized auditor");

        self.entryCount.increment();
        uint256 newEntryId = self.entryCount.current();

        AuditEntry memory newEntry = AuditEntry({
            id: newEntryId,
            actor: actor,
            action: action,
            assetId: assetId,
            timestamp: block.timestamp,
            additionalData: additionalData
        });

        self.entries[newEntryId] = newEntry;

        emit AuditEntryAdded(newEntryId, actor, action, assetId);
    }

    /**
     * @dev Retrieves an audit entry by its ID.
     * @param self The storage struct for the audit trail.
     * @param entryId The ID of the entry to retrieve.
     * @return The requested audit entry.
     */
    function getEntry(AuditTrailStorage storage self, uint256 entryId) internal view returns (AuditEntry memory) {
        require(entryId > 0 && entryId <= self.entryCount.current(), "AuditTrail: Invalid entry ID");
        return self.entries[entryId];
    }

    /**
     * @dev Adds a new valid action to the audit trail.
     * @param self The storage struct for the audit trail.
     * @param action The action to be added.
     */
    function addValidAction(AuditTrailStorage storage self, bytes32 action) internal {
        require(!self.validActions[action], "AuditTrail: Action already exists");
        self.validActions[action] = true;
        emit ActionAdded(action);
    }

    /**
     * @dev Removes a valid action from the audit trail.
     * @param self The storage struct for the audit trail.
     * @param action The action to be removed.
     */
    function removeValidAction(AuditTrailStorage storage self, bytes32 action) internal {
        require(self.validActions[action], "AuditTrail: Action does not exist");
        self.validActions[action] = false;
        emit ActionRemoved(action);
    }

    /**
     * @dev Authorizes an address to add audit entries.
     * @param self The storage struct for the audit trail.
     * @param auditor The address to authorize.
     */
    function authorizeAuditor(AuditTrailStorage storage self, address auditor) internal {
        require(!self.authorizedAuditors[auditor], "AuditTrail: Auditor already authorized");
        self.authorizedAuditors[auditor] = true;
        emit AuditorAuthorized(auditor);
    }

    /**
     * @dev Deauthorizes an address from adding audit entries.
     * @param self The storage struct for the audit trail.
     * @param auditor The address to deauthorize.
     */
    function deauthorizeAuditor(AuditTrailStorage storage self, address auditor) internal {
        require(self.authorizedAuditors[auditor], "AuditTrail: Auditor not authorized");
        self.authorizedAuditors[auditor] = false;
        emit AuditorDeauthorized(auditor);
    }

    /**
     * @dev Checks if an action is valid.
     * @param self The storage struct for the audit trail.
     * @param action The action to check.
     * @return bool indicating if the action is valid.
     */
    function isValidAction(AuditTrailStorage storage self, bytes32 action) internal view returns (bool) {
        return self.validActions[action];
    }

    /**
     * @dev Checks if an address is an authorized auditor.
     * @param self The storage struct for the audit trail.
     * @param auditor The address to check.
     * @return bool indicating if the address is an authorized auditor.
     */
    function isAuthorizedAuditor(AuditTrailStorage storage self, address auditor) internal view returns (bool) {
        return self.authorizedAuditors[auditor];
    }

    /**
     * @dev Gets the total number of audit entries.
     * @param self The storage struct for the audit trail.
     * @return The total number of audit entries.
     */
    function getEntryCount(AuditTrailStorage storage self) internal view returns (uint256) {
        return self.entryCount.current();
    }

    /**
     * @dev Retrieves a range of audit entries.
     * @param self The storage struct for the audit trail.
     * @param startId The starting ID of the range.
     * @param endId The ending ID of the range.
     * @return An array of audit entries within the specified range.
     */
    function getEntryRange(AuditTrailStorage storage self, uint256 startId, uint256 endId) internal view returns (AuditEntry[] memory) {
        require(startId > 0 && startId <= self.entryCount.current(), "AuditTrail: Invalid start ID");
        require(endId >= startId && endId <= self.entryCount.current(), "AuditTrail: Invalid end ID");

        uint256 rangeSize = endId - startId + 1;
        AuditEntry[] memory rangeEntries = new AuditEntry[](rangeSize);

        for (uint256 i = 0; i < rangeSize; i++) {
            rangeEntries[i] = self.entries[startId + i];
        }

        return rangeEntries;
    }
}