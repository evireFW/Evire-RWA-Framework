// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title ComplianceChecks
 * @dev A library for implementing various compliance checks for Real World Assets (RWA) on the blockchain
 */
library ComplianceChecks {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct ComplianceData {
        mapping(address => bool) kycApproved;
        mapping(address => bool) accreditedInvestor;
        mapping(address => uint256) investorRiskScore;
        mapping(address => uint256) lastComplianceCheck;
        EnumerableSet.AddressSet blacklistedAddresses;
        mapping(address => mapping(bytes32 => bool)) jurisdictionApproval;
        uint256 maxInvestorCount;
        uint256 minHoldingPeriod;
        uint256 maxInvestmentAmount;
        address complianceManager;
        bool restrictedTransfer;
        bool paused;
    }

    event ComplianceStatusChanged(address indexed user, bool status);
    event AccreditationStatusChanged(address indexed user, bool status);
    event BlacklistStatusChanged(address indexed user, bool blacklisted);
    event JurisdictionApprovalChanged(address indexed user, bytes32 jurisdiction, bool approved);
    event ComplianceCheckPerformed(address indexed user, uint256 timestamp);
    event RiskScoreUpdated(address indexed user, uint256 newScore);
    event ComplianceManagerUpdated(address indexed newComplianceManager);
    event CompliancePaused(address indexed by);
    event ComplianceUnpaused(address indexed by);

    /**
     * @dev Initializes the compliance data structure
     * @param self The ComplianceData storage pointer
     * @param _complianceManager The address of the compliance manager
     * @param _maxInvestorCount The maximum number of investors allowed
     * @param _minHoldingPeriod The minimum holding period for investments
     * @param _maxInvestmentAmount The maximum investment amount allowed
     * @param _restrictedTransfer Whether transfers are restricted
     */
    function initialize(
        ComplianceData storage self,
        address _complianceManager,
        uint256 _maxInvestorCount,
        uint256 _minHoldingPeriod,
        uint256 _maxInvestmentAmount,
        bool _restrictedTransfer
    ) internal {
        self.complianceManager = _complianceManager;
        self.maxInvestorCount = _maxInvestorCount;
        self.minHoldingPeriod = _minHoldingPeriod;
        self.maxInvestmentAmount = _maxInvestmentAmount;
        self.restrictedTransfer = _restrictedTransfer;
        self.paused = false;
    }

    /**
     * @dev Sets the compliance manager
     * @param self The ComplianceData storage pointer
     * @param _newComplianceManager The address of the new compliance manager
     */
    function setComplianceManager(ComplianceData storage self, address _newComplianceManager) internal {
        require(msg.sender == self.complianceManager, "Only current compliance manager can update manager");
        self.complianceManager = _newComplianceManager;
        emit ComplianceManagerUpdated(_newComplianceManager);
    }

    /**
     * @dev Pauses compliance checks
     * @param self The ComplianceData storage pointer
     */
    function pauseCompliance(ComplianceData storage self) internal {
        require(msg.sender == self.complianceManager, "Only compliance manager can pause compliance");
        require(!self.paused, "Compliance is already paused");
        self.paused = true;
        emit CompliancePaused(msg.sender);
    }

    /**
     * @dev Unpauses compliance checks
     * @param self The ComplianceData storage pointer
     */
    function unpauseCompliance(ComplianceData storage self) internal {
        require(msg.sender == self.complianceManager, "Only compliance manager can unpause compliance");
        require(self.paused, "Compliance is not paused");
        self.paused = false;
        emit ComplianceUnpaused(msg.sender);
    }

    /**
     * @dev Checks if an address is KYC approved
     * @param self The ComplianceData storage pointer
     * @param _address The address to check
     * @return bool True if the address is KYC approved, false otherwise
     */
    function isKYCApproved(ComplianceData storage self, address _address) internal view returns (bool) {
        return self.kycApproved[_address];
    }

    /**
     * @dev Sets the KYC approval status for an address
     * @param self The ComplianceData storage pointer
     * @param _address The address to set the KYC status for
     * @param _status The KYC approval status
     */
    function setKYCApproval(ComplianceData storage self, address _address, bool _status) internal {
        require(msg.sender == self.complianceManager, "Only compliance manager can set KYC approval");
        self.kycApproved[_address] = _status;
        emit ComplianceStatusChanged(_address, _status);
    }

    /**
     * @dev Checks if an address is an accredited investor
     * @param self The ComplianceData storage pointer
     * @param _address The address to check
     * @return bool True if the address is an accredited investor, false otherwise
     */
    function isAccreditedInvestor(ComplianceData storage self, address _address) internal view returns (bool) {
        return self.accreditedInvestor[_address];
    }

    /**
     * @dev Sets the accredited investor status for an address
     * @param self The ComplianceData storage pointer
     * @param _address The address to set the accredited investor status for
     * @param _status The accredited investor status
     */
    function setAccreditedInvestorStatus(ComplianceData storage self, address _address, bool _status) internal {
        require(msg.sender == self.complianceManager, "Only compliance manager can set accredited investor status");
        self.accreditedInvestor[_address] = _status;
        emit AccreditationStatusChanged(_address, _status);
    }

    /**
     * @dev Adds an address to the blacklist
     * @param self The ComplianceData storage pointer
     * @param _address The address to blacklist
     */
    function addToBlacklist(ComplianceData storage self, address _address) internal {
        require(msg.sender == self.complianceManager, "Only compliance manager can add to blacklist");
        self.blacklistedAddresses.add(_address);
        emit BlacklistStatusChanged(_address, true);
    }

    /**
     * @dev Removes an address from the blacklist
     * @param self The ComplianceData storage pointer
     * @param _address The address to remove from the blacklist
     */
    function removeFromBlacklist(ComplianceData storage self, address _address) internal {
        require(msg.sender == self.complianceManager, "Only compliance manager can remove from blacklist");
        self.blacklistedAddresses.remove(_address);
        emit BlacklistStatusChanged(_address, false);
    }

    /**
     * @dev Checks if an address is blacklisted
     * @param self The ComplianceData storage pointer
     * @param _address The address to check
     * @return bool True if the address is blacklisted, false otherwise
     */
    function isBlacklisted(ComplianceData storage self, address _address) internal view returns (bool) {
        return self.blacklistedAddresses.contains(_address);
    }

    /**
     * @dev Sets the jurisdiction approval for an address
     * @param self The ComplianceData storage pointer
     * @param _address The address to set the jurisdiction approval for
     * @param _jurisdiction The jurisdiction identifier
     * @param _approved The approval status
     */
    function setJurisdictionApproval(
        ComplianceData storage self,
        address _address,
        bytes32 _jurisdiction,
        bool _approved
    ) internal {
        require(msg.sender == self.complianceManager, "Only compliance manager can set jurisdiction approval");
        self.jurisdictionApproval[_address][_jurisdiction] = _approved;
        emit JurisdictionApprovalChanged(_address, _jurisdiction, _approved);
    }

    /**
     * @dev Checks if an address is approved for a specific jurisdiction
     * @param self The ComplianceData storage pointer
     * @param _address The address to check
     * @param _jurisdiction The jurisdiction identifier
     * @return bool True if the address is approved for the jurisdiction, false otherwise
     */
    function isApprovedForJurisdiction(
        ComplianceData storage self,
        address _address,
        bytes32 _jurisdiction
    ) internal view returns (bool) {
        return self.jurisdictionApproval[_address][_jurisdiction];
    }

    /**
     * @dev Updates the risk score for an address
     * @param self The ComplianceData storage pointer
     * @param _address The address to update the risk score for
     * @param _score The new risk score
     */
    function updateRiskScore(ComplianceData storage self, address _address, uint256 _score) internal {
        require(msg.sender == self.complianceManager, "Only compliance manager can update risk score");
        self.investorRiskScore[_address] = _score;
        emit RiskScoreUpdated(_address, _score);
    }

    /**
     * @dev Performs a compliance check for an address
     * @param self The ComplianceData storage pointer
     * @param _address The address to perform the compliance check for
     * @return bool True if the address passes all compliance checks, false otherwise
     */
    function performComplianceCheck(ComplianceData storage self, address _address) internal returns (bool) {
        require(!self.paused, "Compliance checks are paused");
        bool isCompliant = isKYCApproved(self, _address) &&
            !isBlacklisted(self, _address) &&
            (self.investorRiskScore[_address] < 75); // Example risk threshold

        self.lastComplianceCheck[_address] = block.timestamp;
        emit ComplianceCheckPerformed(_address, block.timestamp);

        return isCompliant;
    }

    /**
     * @dev Checks if a transfer is compliant
     * @param self The ComplianceData storage pointer
     * @param _from The sender's address
     * @param _to The recipient's address
     * @param _amount The transfer amount
     * @return bool True if the transfer is compliant, false otherwise
     */
    function isTransferCompliant(
        ComplianceData storage self,
        address _from,
        address _to,
        uint256 _amount
    ) internal view returns (bool) {
        require(!self.paused, "Compliance checks are paused");
        if (self.restrictedTransfer) {
            require(isKYCApproved(self, _to), "Recipient is not KYC approved");
            require(!isBlacklisted(self, _to), "Recipient is blacklisted");
            require(_amount <= self.maxInvestmentAmount, "Transfer amount exceeds maximum allowed");
        }
        return true;
    }

    /**
     * @dev Checks if the minimum holding period has passed for an address
     * @param self The ComplianceData storage pointer
     * @param _address The address to check
     * @param _initialInvestmentTime The timestamp of the initial investment
     * @return bool True if the minimum holding period has passed, false otherwise
     */
    function hasMinHoldingPeriodPassed(
        ComplianceData storage self,
        address _address,
        uint256 _initialInvestmentTime
    ) internal view returns (bool) {
        return (block.timestamp - _initialInvestmentTime) >= self.minHoldingPeriod;
    }

    /**
     * @dev Checks if adding a new investor would exceed the maximum investor count
     * @param self The ComplianceData storage pointer
     * @param _currentInvestorCount The current number of investors
     * @return bool True if adding a new investor is allowed, false otherwise
     */
    function canAddNewInvestor(ComplianceData storage self, uint256 _currentInvestorCount) internal view returns (bool) {
        return _currentInvestorCount < self.maxInvestorCount;
    }
}
