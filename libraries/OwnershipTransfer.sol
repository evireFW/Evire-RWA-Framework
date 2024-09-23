// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ComplianceChecks.sol";
import "./DataVerification.sol";
import "./AuditTrail.sol";

/**
 * @title OwnershipTransfer
 * @dev Library for managing ownership transfers of Real World Assets (RWA) on the blockchain
 */
library OwnershipTransfer {
    using ComplianceChecks for address;
    using DataVerification for bytes32;
    using AuditTrail for address;

    enum TransferStatus { Pending, Approved, Rejected, Completed, Cancelled }

    struct Transfer {
        address from;
        address to;
        uint256 assetId;
        uint256 timestamp;
        TransferStatus status;
        bytes32 complianceHash;
        bytes32 legalDocumentHash;
    }

    event TransferInitiated(uint256 indexed transferId, address indexed from, address indexed to, uint256 assetId);
    event TransferApproved(uint256 indexed transferId);
    event TransferRejected(uint256 indexed transferId, string reason);
    event TransferCompleted(uint256 indexed transferId);
    event TransferCancelled(uint256 indexed transferId);

    /**
     * @dev Initiates an ownership transfer
     * @param transfers The mapping of transferId to Transfer structs
     * @param from The current owner's address
     * @param to The new owner's address
     * @param assetId The ID of the asset being transferred
     * @param complianceHash The hash of the compliance documents
     * @param legalDocumentHash The hash of the legal transfer documents
     * @return transferId The unique ID of the transfer
     */
    function initiateTransfer(
        mapping(uint256 => Transfer) storage transfers,
        address from,
        address to,
        uint256 assetId,
        bytes32 complianceHash,
        bytes32 legalDocumentHash
    ) internal returns (uint256 transferId) {
        require(from != address(0) && to != address(0), "Invalid addresses");
        require(from != to, "Cannot transfer to self");
        
        transferId = uint256(keccak256(abi.encodePacked(from, to, assetId, block.timestamp)));
        require(transfers[transferId].timestamp == 0, "Transfer already exists");

        transfers[transferId] = Transfer({
            from: from,
            to: to,
            assetId: assetId,
            timestamp: block.timestamp,
            status: TransferStatus.Pending,
            complianceHash: complianceHash,
            legalDocumentHash: legalDocumentHash
        });

        emit TransferInitiated(transferId, from, to, assetId);
    }

    /**
     * @dev Approves an ownership transfer
     * @param transfers The mapping of transferId to Transfer structs
     * @param transferId The ID of the transfer to approve
     */
    function approveTransfer(mapping(uint256 => Transfer) storage transfers, uint256 transferId) internal {
        Transfer storage transfer = transfers[transferId];
        require(transfer.status == TransferStatus.Pending, "Transfer not in pending state");
        require(transfer.to.isCompliant(), "Recipient not compliant");
        require(transfer.complianceHash.isVerified(), "Compliance documents not verified");
        require(transfer.legalDocumentHash.isVerified(), "Legal documents not verified");

        transfer.status = TransferStatus.Approved;
        emit TransferApproved(transferId);
    }

    /**
     * @dev Rejects an ownership transfer
     * @param transfers The mapping of transferId to Transfer structs
     * @param transferId The ID of the transfer to reject
     * @param reason The reason for rejection
     */
    function rejectTransfer(mapping(uint256 => Transfer) storage transfers, uint256 transferId, string memory reason) internal {
        Transfer storage transfer = transfers[transferId];
        require(transfer.status == TransferStatus.Pending, "Transfer not in pending state");
        
        transfer.status = TransferStatus.Rejected;
        emit TransferRejected(transferId, reason);
    }

    /**
     * @dev Completes an approved ownership transfer
     * @param transfers The mapping of transferId to Transfer structs
     * @param transferId The ID of the transfer to complete
     */
    function completeTransfer(mapping(uint256 => Transfer) storage transfers, uint256 transferId) internal {
        Transfer storage transfer = transfers[transferId];
        require(transfer.status == TransferStatus.Approved, "Transfer not approved");
        require(transfer.to == msg.sender, "Only recipient can complete transfer");
        
        transfer.status = TransferStatus.Completed;
        transfer.from.logAuditTrail("Asset transferred", transfer.assetId);
        transfer.to.logAuditTrail("Asset received", transfer.assetId);
        
        emit TransferCompleted(transferId);
    }

    /**
     * @dev Cancels a pending ownership transfer
     * @param transfers The mapping of transferId to Transfer structs
     * @param transferId The ID of the transfer to cancel
     */
    function cancelTransfer(mapping(uint256 => Transfer) storage transfers, uint256 transferId) internal {
        Transfer storage transfer = transfers[transferId];
        require(transfer.status == TransferStatus.Pending, "Transfer not in pending state");
        require(transfer.from == msg.sender, "Only sender can cancel transfer");
        
        transfer.status = TransferStatus.Cancelled;
        emit TransferCancelled(transferId);
    }

    /**
     * @dev Checks if a transfer is valid and can be completed
     * @param transfers The mapping of transferId to Transfer structs
     * @param transferId The ID of the transfer to check
     * @return bool indicating if the transfer is valid
     */
    function isValidTransfer(mapping(uint256 => Transfer) storage transfers, uint256 transferId) internal view returns (bool) {
        Transfer storage transfer = transfers[transferId];
        return (transfer.status == TransferStatus.Approved &&
                transfer.to.isCompliant() &&
                transfer.complianceHash.isVerified() &&
                transfer.legalDocumentHash.isVerified());
    }

    /**
     * @dev Retrieves the current status of a transfer
     * @param transfers The mapping of transferId to Transfer structs
     * @param transferId The ID of the transfer to check
     * @return TransferStatus enum representing the current status
     */
    function getTransferStatus(mapping(uint256 => Transfer) storage transfers, uint256 transferId) internal view returns (TransferStatus) {
        return transfers[transferId].status;
    }

    /**
     * @dev Calculates the time elapsed since the transfer was initiated
     * @param transfers The mapping of transferId to Transfer structs
     * @param transferId The ID of the transfer to check
     * @return uint256 representing the time elapsed in seconds
     */
    function getTimeElapsed(mapping(uint256 => Transfer) storage transfers, uint256 transferId) internal view returns (uint256) {
        return block.timestamp - transfers[transferId].timestamp;
    }
}
