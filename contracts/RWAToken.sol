// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../libraries/ComplianceChecks.sol";
import "../libraries/AssetValuation.sol";

contract RWAToken is ERC20, ERC20Pausable, AccessControl {
    using ComplianceChecks for address;
    using AssetValuation for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant COMPLIANCE_ROLE = keccak256("COMPLIANCE_ROLE");

    uint256 public constant MAX_SUPPLY = 1_000_000 * 10**18; // 1 million tokens with 18 decimals
    uint256 public assetValue;
    string public assetIdentifier;

    mapping(address => bool) public whitelist;

    event AssetValueUpdated(uint256 newValue);
    event AddressWhitelisted(address indexed account);
    event AddressRemovedFromWhitelist(address indexed account);
    event TokensBurned(address indexed burner, uint256 amount);

    constructor(
        string memory name,
        string memory symbol,
        string memory _assetIdentifier
    ) ERC20(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(PAUSER_ROLE, msg.sender);
        _setupRole(COMPLIANCE_ROLE, msg.sender);
        assetIdentifier = _assetIdentifier;
    }

    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        require(to != address(0), "Cannot mint to zero address");
        require(amount > 0, "Amount must be greater than zero");
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");
        require(whitelist[to], "Recipient not whitelisted");
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function updateAssetValue(uint256 newValue) external onlyRole(DEFAULT_ADMIN_ROLE) {
        assetValue = newValue.validateAssetValue();
        emit AssetValueUpdated(assetValue);
    }

    function addToWhitelist(address account) external onlyRole(COMPLIANCE_ROLE) {
        require(account != address(0), "Cannot whitelist zero address");
        require(account.checkCompliance(), "Address does not meet compliance requirements");
        whitelist[account] = true;
        emit AddressWhitelisted(account);
    }

    function removeFromWhitelist(address account) external onlyRole(COMPLIANCE_ROLE) {
        require(account != address(0), "Cannot remove zero address");
        whitelist[account] = false;
        emit AddressRemovedFromWhitelist(account);
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(whitelist[msg.sender], "Sender not whitelisted");
        require(whitelist[recipient], "Recipient not whitelisted");
        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        require(whitelist[sender], "Sender not whitelisted");
        require(whitelist[recipient], "Recipient not whitelisted");
        return super.transferFrom(sender, recipient, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }
}
