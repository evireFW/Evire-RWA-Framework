// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICompliance.sol";

/**
 * @title Compliance
 * @dev Implements compliance rules for Real World Assets (RWA) on the blockchain
 */
contract Compliance is ICompliance, Ownable {
    struct Rule {
        string name;
        string description;
        bool isActive;
    }

    uint256 private _ruleIdCounter;
    mapping(uint256 => Rule) public rules;
    mapping(address => bool) public whitelistedAddresses;
    mapping(address => mapping(uint256 => bool)) public addressCompliance;

    event RuleAdded(uint256 indexed ruleId, string name);
    event RuleUpdated(uint256 indexed ruleId, string name, bool isActive);
    event AddressWhitelisted(address indexed account);
    event AddressBlacklisted(address indexed account);
    event ComplianceUpdated(address indexed account, uint256 indexed ruleId, bool status);

    constructor() {
        _addRule("KYC", "Know Your Customer verification");
    }

    function addRule(string memory name, string memory description) external onlyOwner {
        _addRule(name, description);
    }

    function _addRule(string memory name, string memory description) internal {
        uint256 ruleId = _ruleIdCounter;
        rules[ruleId] = Rule(name, description, true);
        _ruleIdCounter += 1;
        emit RuleAdded(ruleId, name);
    }

    function updateRule(uint256 ruleId, bool isActive) external onlyOwner {
        require(ruleId < _ruleIdCounter, "Rule does not exist");
        rules[ruleId].isActive = isActive;
        emit RuleUpdated(ruleId, rules[ruleId].name, isActive);
    }

    function whitelistAddress(address account) external onlyOwner {
        whitelistedAddresses[account] = true;
        emit AddressWhitelisted(account);
    }

    function blacklistAddress(address account) external onlyOwner {
        whitelistedAddresses[account] = false;
        emit AddressBlacklisted(account);
    }

    function updateAddressCompliance(address account, uint256 ruleId, bool status) external onlyOwner {
        require(ruleId < _ruleIdCounter, "Rule does not exist");
        addressCompliance[account][ruleId] = status;
        emit ComplianceUpdated(account, ruleId, status);
    }

    function isCompliant(address account) public view override returns (bool) {
        if (!whitelistedAddresses[account]) {
            return false;
        }

        for (uint256 i = 0; i < _ruleIdCounter; i++) {
            if (rules[i].isActive && !addressCompliance[account][i]) {
                return false;
            }
        }

        return true;
    }

    function getRuleCount() public view returns (uint256) {
        return _ruleIdCounter;
    }
}
