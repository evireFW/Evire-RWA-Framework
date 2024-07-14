// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ICompliance
 * @dev Interface for the Compliance contract in the Evire-RWA-Framework
 */
interface ICompliance {
    /**
     * @dev Checks if a transfer of tokens is compliant
     * @param from The address sending the tokens
     * @param to The address receiving the tokens
     * @param amount The amount of tokens being transferred
     * @return bool Returns true if the transfer is compliant, false otherwise
     */
    function checkTransferCompliance(address from, address to, uint256 amount) external view returns (bool);

    /**
     * @dev Checks if an address is whitelisted
     * @param account The address to check
     * @return bool Returns true if the address is whitelisted, false otherwise
     */
    function isWhitelisted(address account) external view returns (bool);

    /**
     * @dev Adds an address to the whitelist
     * @param account The address to whitelist
     */
    function addToWhitelist(address account) external;

    /**
     * @dev Removes an address from the whitelist
     * @param account The address to remove from the whitelist
     */
    function removeFromWhitelist(address account) external;

    /**
     * @dev Checks if the total supply is within the allowed limits
     * @param currentSupply The current total supply
     * @param amount The amount to be added or removed from the supply
     * @param isIncrease True if the amount is being added, false if being removed
     * @return bool Returns true if the supply change is compliant, false otherwise
     */
    function checkSupplyLimit(uint256 currentSupply, uint256 amount, bool isIncrease) external view returns (bool);

    /**
     * @dev Updates the compliance rules
     * @param newRules The new compliance rules (implementation-specific format)
     */
    function updateComplianceRules(bytes calldata newRules) external;

    /**
     * @dev Checks if an address is a verified investor
     * @param investor The address to check
     * @return bool Returns true if the address is a verified investor, false otherwise
     */
    function isVerifiedInvestor(address investor) external view returns (bool);

    /**
     * @dev Verifies an investor
     * @param investor The address of the investor to verify
     * @param data Additional data required for verification (implementation-specific)
     */
    function verifyInvestor(address investor, bytes calldata data) external;

    /**
     * @dev Revokes the verification status of an investor
     * @param investor The address of the investor to revoke verification from
     */
    function revokeInvestorVerification(address investor) external;

    /**
     * @dev Event emitted when compliance rules are updated
     * @param updater The address that updated the rules
     * @param newRulesHash The hash of the new rules
     */
    event ComplianceRulesUpdated(address indexed updater, bytes32 newRulesHash);

    /**
     * @dev Event emitted when an investor's verification status changes
     * @param investor The address of the investor
     * @param isVerified The new verification status
     */
    event InvestorVerificationChanged(address indexed investor, bool isVerified);
}