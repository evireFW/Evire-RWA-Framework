// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./RWAAsset.sol";

/**
 * @title ResourceAllocation
 * @dev Manages the allocation of resources for Real World Assets (RWA)
 */
contract ResourceAllocation is Ownable {
    struct Resource {
        string name;
        uint256 totalSupply;
        uint256 allocatedAmount;
        bool isActive;
    }

    struct Allocation {
        uint256 amount;
        uint256 timestamp;
    }

    mapping(uint256 => Resource) public resources;
    mapping(address => mapping(uint256 => Allocation)) public assetAllocations;
    uint256 public resourceCount;

    event ResourceAdded(uint256 indexed resourceId, string name, uint256 totalSupply);
    event ResourceUpdated(uint256 indexed resourceId, uint256 newTotalSupply);
    event ResourceAllocated(address indexed assetAddress, uint256 indexed resourceId, uint256 amount);
    event ResourceDeallocated(address indexed assetAddress, uint256 indexed resourceId, uint256 amount);
    event ResourceDeactivated(uint256 indexed resourceId);
    event ResourceActivated(uint256 indexed resourceId);

    modifier resourceExists(uint256 _resourceId) {
        require(bytes(resources[_resourceId].name).length > 0, "Resource does not exist");
        _;
    }

    modifier resourceIsActive(uint256 _resourceId) {
        require(resources[_resourceId].isActive, "Resource is not active");
        _;
    }

    modifier validAsset(address _assetAddress) {
        require(RWAAsset(_assetAddress).isValidAsset(), "Invalid RWA asset address");
        _;
    }

    constructor() {
        resourceCount = 0;
    }

    /**
     * @dev Adds a new resource to the system
     * @param _name Name of the resource
     * @param _totalSupply Total supply of the resource
     */
    function addResource(string memory _name, uint256 _totalSupply) public onlyOwner {
        resourceCount += 1;
        resources[resourceCount] = Resource(_name, _totalSupply, 0, true);
        emit ResourceAdded(resourceCount, _name, _totalSupply);
    }

    /**
     * @dev Updates the total supply of an existing resource
     * @param _resourceId ID of the resource to update
     * @param _newTotalSupply New total supply of the resource
     */
    function updateResourceSupply(uint256 _resourceId, uint256 _newTotalSupply) public onlyOwner resourceExists(_resourceId) {
        require(_newTotalSupply >= resources[_resourceId].allocatedAmount, "New supply cannot be less than allocated amount");
        resources[_resourceId].totalSupply = _newTotalSupply;
        emit ResourceUpdated(_resourceId, _newTotalSupply);
    }

    /**
     * @dev Deactivates a resource
     * @param _resourceId ID of the resource to deactivate
     */
    function deactivateResource(uint256 _resourceId) public onlyOwner resourceExists(_resourceId) {
        resources[_resourceId].isActive = false;
        emit ResourceDeactivated(_resourceId);
    }

    /**
     * @dev Activates a resource
     * @param _resourceId ID of the resource to activate
     */
    function activateResource(uint256 _resourceId) public onlyOwner resourceExists(_resourceId) {
        require(!resources[_resourceId].isActive, "Resource is already active");
        resources[_resourceId].isActive = true;
        emit ResourceActivated(_resourceId);
    }

    /**
     * @dev Allocates a resource to a specific RWA asset
     * @param _assetAddress Address of the RWA asset
     * @param _resourceId ID of the resource to allocate
     * @param _amount Amount of the resource to allocate
     */
    function allocateResource(address _assetAddress, uint256 _resourceId, uint256 _amount) public onlyOwner resourceExists(_resourceId) resourceIsActive(_resourceId) validAsset(_assetAddress) {
        require(resources[_resourceId].totalSupply - resources[_resourceId].allocatedAmount >= _amount, "Insufficient resource available");

        resources[_resourceId].allocatedAmount += _amount;
        assetAllocations[_assetAddress][_resourceId].amount += _amount;
        assetAllocations[_assetAddress][_resourceId].timestamp = block.timestamp;

        emit ResourceAllocated(_assetAddress, _resourceId, _amount);
    }

    /**
     * @dev Deallocates a resource from a specific RWA asset
     * @param _assetAddress Address of the RWA asset
     * @param _resourceId ID of the resource to deallocate
     * @param _amount Amount of the resource to deallocate
     */
    function deallocateResource(address _assetAddress, uint256 _resourceId, uint256 _amount) public onlyOwner resourceExists(_resourceId) {
        require(assetAllocations[_assetAddress][_resourceId].amount >= _amount, "Insufficient allocated amount");

        resources[_resourceId].allocatedAmount -= _amount;
        assetAllocations[_assetAddress][_resourceId].amount -= _amount;
        assetAllocations[_assetAddress][_resourceId].timestamp = block.timestamp;

        emit ResourceDeallocated(_assetAddress, _resourceId, _amount);
    }

    /**
     * @dev Allows an asset to deallocate its own resources
     * @param _resourceId ID of the resource to deallocate
     * @param _amount Amount of the resource to deallocate
     */
    function deallocateResourceByAsset(uint256 _resourceId, uint256 _amount) public resourceExists(_resourceId) {
        require(assetAllocations[msg.sender][_resourceId].amount >= _amount, "Insufficient allocated amount");

        resources[_resourceId].allocatedAmount -= _amount;
        assetAllocations[msg.sender][_resourceId].amount -= _amount;
        assetAllocations[msg.sender][_resourceId].timestamp = block.timestamp;

        emit ResourceDeallocated(msg.sender, _resourceId, _amount);
    }

    /**
     * @dev Retrieves the current allocation of a resource for a specific RWA asset
     * @param _assetAddress Address of the RWA asset
     * @param _resourceId ID of the resource
     * @return amount The amount of the resource allocated to the asset
     * @return timestamp The timestamp of the last allocation or deallocation
     */
    function getResourceAllocation(address _assetAddress, uint256 _resourceId) public view returns (uint256 amount, uint256 timestamp) {
        return (
            assetAllocations[_assetAddress][_resourceId].amount,
            assetAllocations[_assetAddress][_resourceId].timestamp
        );
    }

    /**
     * @dev Retrieves the available amount of a resource
     * @param _resourceId ID of the resource
     * @return The available amount of the resource
     */
    function getAvailableResourceAmount(uint256 _resourceId) public view resourceExists(_resourceId) returns (uint256) {
        return resources[_resourceId].totalSupply - resources[_resourceId].allocatedAmount;
    }
}
