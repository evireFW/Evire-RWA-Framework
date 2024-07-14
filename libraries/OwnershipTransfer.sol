// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ComplianceChecks.sol";
import "./DataVerification.sol";
import "./AuditTrail.sol";

/**
 * @title OwnershipTransfer
 * @dev Library for managing ownership transfers of Real World Assets (RWA) on the blockchain
 */
library OwnershipTransfer {
    using SafeMath for uint256;
    using ComplianceChecks for address;
    using DataVerification for bytes32;
    using AuditTrail for address;

    struct Transfer {
        address from;
        address to;
        uint256 assetId;
        uint256 timestamp;
        TransferStatus status;
        bytes32 complianceHash;
        bytes32 legalDocumentHash;
    }

    enum TransferStatus { Pending, Approved, Rejected, Completed, Cancelled }

    event TransferInitiated(uint256 indexed transferId, address indexed from, address indexed to, uint256 assetId);
    event TransferApproved(uint256 indexed transferId);
    event TransferRejected(uint256 indexed transferId, string reason);
    event TransferCompleted(uint256 indexed transferId);
    event TransferCancelled(uint256 indexed transferId);

    /**
     * @dev Initiates an ownership transfer
     * @param self The Transfer struct
     * @param from The current owner's address
     * @param to The new owner's address
     * @param assetId The ID of the asset being transferred
     * @param complianceHash The hash of the compliance documents
     * @param legalDocumentHash The hash of the legal transfer documents
     * @return transferId The unique ID of the transfer
     */
    function initiateTransfer(
        Transfer storage self,
        address from,
        address to,
        uint256 assetId,
        bytes32 complianceHash,
        bytes32 legalDocumentHash
    ) internal returns (uint256 transferId) {
        require(from != address(0) && to != address(0), "Invalid addresses");
        require(from != to, "Cannot transfer to self");
        
        transferId = uint256(keccak256(abi.encodePacked(from, to, assetId, block.timestamp)));
        
        self.from = from;
        self.to = to;
        self.assetId = assetId;
        self.timestamp = block.timestamp;
        self.status = TransferStatus.Pending;
        self.complianceHash = complianceHash;
        self.legalDocumentHash = legalDocumentHash;

        emit TransferInitiated(transferId, from, to, assetId);
    }

    /**
     * @dev Approves an ownership transfer
     * @param self The Transfer struct
     * @param transferId The ID of the transfer to approve
     */
    function approveTransfer(Transfer storage self, uint256 transferId) internal {
        require(self.status == TransferStatus.Pending, "Transfer not in pending state");
        require(self.to.isCompliant(), "Recipient not compliant");
        require(self.complianceHash.isVerified(), "Compliance documents not verified");
        require(self.legalDocumentHash.isVerified(), "Legal documents not verified");

        self.status = TransferStatus.Approved;
        emit TransferApproved(transferId);
    }

    /**
     * @dev Rejects an ownership transfer
     * @param self The Transfer struct
     * @param transferId The ID of the transfer to reject
     * @param reason The reason for rejection
     */
    function rejectTransfer(Transfer storage self, uint256 transferId, string memory reason) internal {
        require(self.status == TransferStatus.Pending, "Transfer not in pending state");
        
        self.status = TransferStatus.Rejected;
        emit TransferRejected(transferId, reason);
    }

    /**
     * @dev Completes an approved ownership transfer
     * @param self The Transfer struct
     * @param transferId The ID of the transfer to complete
     */
    function completeTransfer(Transfer storage self, uint256 transferId) internal {
        require(self.status == TransferStatus.Approved, "Transfer not approved");
        
        self.status = TransferStatus.Completed;
        self.from.logAuditTrail("Asset transferred", self.assetId);
        self.to.logAuditTrail("Asset received", self.assetId);
        
        emit TransferCompleted(transferId);
    }

    /**
     * @dev Cancels a pending ownership transfer
     * @param self The Transfer struct
     * @param transferId The ID of the transfer to cancel
     */
    function cancelTransfer(Transfer storage self, uint256 transferId) internal {
        require(self.status == TransferStatus.Pending, "Transfer not in pending state");
        
        self.status = TransferStatus.Cancelled;
        emit TransferCancelled(transferId);
    }

    /**
     * @dev Checks if a transfer is valid and can be completed
     * @param self The Transfer struct
     * @return bool indicating if the transfer is valid
     */
    function isValidTransfer(Transfer storage self) internal view returns (bool) {
        return (self.status == TransferStatus.Approved &&
                self.to.isCompliant() &&
                self.complianceHash.isVerified() &&
                self.legalDocumentHash.isVerified());
    }

    /**
     * @dev Retrieves the current status of a transfer
     * @param self The Transfer struct
     * @return TransferStatus enum representing the current status
     */
    function getTransferStatus(Transfer storage self) internal view returns (TransferStatus) {
        return self.status;
    }

    /**
     * @dev Calculates the time elapsed since the transfer was initiated
     * @param self The Transfer struct
     * @return uint256 representing the time elapsed in seconds
     */
    function getTimeElapsed(Transfer storage self) internal view returns (uint256) {
        return block.timestamp.sub(self.timestamp);
    }
}