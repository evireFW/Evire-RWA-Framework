// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../libraries/ComplianceChecks.sol";
import "../libraries/AssetValuation.sol";

contract RWAToken is ERC20, ERC20Pausable, AccessControl, ReentrancyGuard {
    using ComplianceChecks for address;
    using AssetValuation for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");

    uint256 public constant MAX_SUPPLY = 1000000 * 10**18; // 1 million tokens
    uint256 public assetValue;
    string public assetIdentifier;

    mapping(address => bool) public whitelist;

    event AssetValueUpdated(uint256 newValue);
    event AddressWhitelisted(address indexed account);
    event AddressRemovedFromWhitelist(address indexed account);

    constructor(string memory name, string memory symbol, string memory _assetIdentifier) 
        ERC20(name, symbol) 
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(COMPLIANCE_ROLE, msg.sender);
        assetIdentifier = _assetIdentifier;
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");
        require(whitelist[to], "Recipient not whitelisted");
        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function updateAssetValue(uint256 newValue) public onlyRole(DEFAULT_ADMIN_ROLE) {
        assetValue = newValue.validateAssetValue();
        emit AssetValueUpdated(newValue);
    }

    function addToWhitelist(address account) public onlyRole(COMPLIANCE_ROLE) {
        require(account.checkCompliance(), "Address does not meet compliance requirements");
        whitelist[account] = true;
        emit AddressWhitelisted(account);
    }

    function removeFromWhitelist(address account) public onlyRole(COMPLIANCE_ROLE) {
        whitelist[account] = false;
        emit AddressRemovedFromWhitelist(account);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(whitelist[recipient], "Recipient not whitelisted");
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(whitelist[recipient], "Recipient not whitelisted");
        return super.transferFrom(sender, recipient, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}