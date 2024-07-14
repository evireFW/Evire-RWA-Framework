// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "../libraries/AssetValuation.sol";
import "../libraries/ComplianceChecks.sol";
import "../libraries/DataVerification.sol";
import "../libraries/OwnershipTransfer.sol";
import "../libraries/AssetTokenization.sol";
import "../libraries/RiskAssessment.sol";
import "../libraries/AuditTrail.sol";

/**
 * @title RWAAsset
 * @dev Manages the lifecycle and operations of a Real World Asset (RWA) on the blockchain
 */
contract RWAAsset is 
    Initializable, 
    ERC721Upgradeable, 
    AccessControlUpgradeable, 
    PausableUpgradeable, 
    UUPSUpgradeable 
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using AssetValuation for uint256;
    using ComplianceChecks for address;
    using DataVerification for bytes32;
    using OwnershipTransfer for uint256;
    using AssetTokenization for uint256;
    using RiskAssessment for uint256;
    using AuditTrail for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    CountersUpgradeable.Counter private _tokenIdCounter;

    struct Asset {
        string assetType;
        uint256 originalValue;
        uint256 currentValue;
        uint256 tokenizationPercentage;
        uint256 lastValuationTimestamp;
        string metadataURI;
        bool isTokenized;
        address custodian;
        RiskAssessment.RiskLevel riskLevel;
    }

    mapping(uint256 => Asset) public assets;
    mapping(uint256 => mapping(address => uint256)) public assetShares;
    mapping(address => bool) public whitelist;

    AggregatorV3Interface private priceFeed;
    IERC20Upgradeable public paymentToken;

    event AssetCreated(uint256 indexed tokenId, string assetType, uint256 originalValue);
    event AssetValueUpdated(uint256 indexed tokenId, uint256 newValue);
    event AssetTokenized(uint256 indexed tokenId, uint256 tokenizationPercentage);
    event ShareTransferred(uint256 indexed tokenId, address from, address to, uint256 amount);
    event RiskLevelUpdated(uint256 indexed tokenId, RiskAssessment.RiskLevel newRiskLevel);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name,
        string memory symbol,
        address _priceFeedAddress,
        address _paymentTokenAddress
    ) public initializer {
        __ERC721_init(name, symbol);
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        priceFeed = AggregatorV3Interface(_priceFeedAddress);
        paymentToken = IERC20Upgradeable(_paymentTokenAddress);
    }

    function createAsset(
        string memory assetType,
        uint256 originalValue,
        string memory metadataURI,
        address custodian
    ) public onlyRole(MINTER_ROLE) returns (uint256) {
        require(custodian.isCompliant(), "Custodian is not compliant");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(custodian, tokenId);

        assets[tokenId] = Asset({
            assetType: assetType,
            originalValue: originalValue,
            currentValue: originalValue,
            tokenizationPercentage: 0,
            lastValuationTimestamp: block.timestamp,
            metadataURI: metadataURI,
            isTokenized: false,
            custodian: custodian,
            riskLevel: RiskAssessment.RiskLevel.Medium
        });

        tokenId.initializeAuditTrail();

        emit AssetCreated(tokenId, assetType, originalValue);
        return tokenId;
    }

    function updateAssetValue(uint256 tokenId, uint256 newValue) public onlyRole(ADMIN_ROLE) {
        require(_exists(tokenId), "Asset does not exist");
        Asset storage asset = assets[tokenId];

        uint256 verifiedValue = newValue.verifyAssetValue(priceFeed);
        asset.currentValue = verifiedValue;
        asset.lastValuationTimestamp = block.timestamp;

        tokenId.logValueUpdate(verifiedValue);

        emit AssetValueUpdated(tokenId, verifiedValue);
    }

    function tokenizeAsset(uint256 tokenId, uint256 percentage) public onlyRole(ADMIN_ROLE) {
        require(_exists(tokenId), "Asset does not exist");
        require(!assets[tokenId].isTokenized, "Asset is already tokenized");
        require(percentage > 0 && percentage <= 100, "Invalid tokenization percentage");

        Asset storage asset = assets[tokenId];
        asset.tokenizationPercentage = percentage;
        asset.isTokenized = true;

        uint256 tokenizedValue = asset.currentValue.calculateTokenizedValue(percentage);
        tokenId.createTokenizedShares(tokenizedValue);

        tokenId.logTokenization(percentage);

        emit AssetTokenized(tokenId, percentage);
    }

    function transferShares(uint256 tokenId, address to, uint256 amount) public whenNotPaused {
        require(_exists(tokenId), "Asset does not exist");
        require(assets[tokenId].isTokenized, "Asset is not tokenized");
        require(assetShares[tokenId][msg.sender] >= amount, "Insufficient shares");
        require(whitelist[to], "Recipient is not whitelisted");

        assetShares[tokenId][msg.sender] -= amount;
        assetShares[tokenId][to] += amount;

        tokenId.logShareTransfer(msg.sender, to, amount);

        emit ShareTransferred(tokenId, msg.sender, to, amount);
    }

    function updateRiskAssessment(uint256 tokenId) public onlyRole(ADMIN_ROLE) {
        require(_exists(tokenId), "Asset does not exist");
        Asset storage asset = assets[tokenId];

        RiskAssessment.RiskLevel newRiskLevel = tokenId.assessRisk(
            asset.currentValue,
            asset.originalValue,
            asset.lastValuationTimestamp
        );

        asset.riskLevel = newRiskLevel;

        tokenId.logRiskUpdate(newRiskLevel);

        emit RiskLevelUpdated(tokenId, newRiskLevel);
    }

    function whitelistAddress(address account) public onlyRole(ADMIN_ROLE) {
        require(!whitelist[account], "Address already whitelisted");
        whitelist[account] = true;
    }

    function blacklistAddress(address account) public onlyRole(ADMIN_ROLE) {
        require(whitelist[account], "Address not whitelisted");
        whitelist[account] = false;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        require(whitelist[to], "Recipient is not whitelisted");
        require(to.isCompliant(), "Recipient is not compliant");

        tokenId.verifyOwnershipTransfer(from, to);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Asset does not exist");
        return assets[tokenId].metadataURI;
    }
}