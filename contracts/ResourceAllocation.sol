// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./RWAAsset.sol";

/**
 * @title ResourceAllocation
 * @dev Manages the allocation of resources for Real World Assets (RWA)
 */
contract ResourceAllocation is Ownable {
    using SafeMath for uint256;

    struct Resource {
        string name;
        uint256 totalSupply;
        uint256 allocatedAmount;
        bool isActive;
    }

    struct Allocation {
        uint256 resourceId;
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

    constructor() {
        resourceCount = 0;
    }

    /**
     * @dev Adds a new resource to the system
     * @param _name Name of the resource
     * @param _totalSupply Total supply of the resource
     */
    function addResource(string memory _name, uint256 _totalSupply) public onlyOwner {
        resourceCount = resourceCount.add(1);
        resources[resourceCount] = Resource(_name, _totalSupply, 0, true);
        emit ResourceAdded(resourceCount, _name, _totalSupply);
    }

    /**
     * @dev Updates the total supply of an existing resource
     * @param _resourceId ID of the resource to update
     * @param _newTotalSupply New total supply of the resource
     */
    function updateResourceSupply(uint256 _resourceId, uint256 _newTotalSupply) public onlyOwner {
        require(resources[_resourceId].isActive, "Resource does not exist");
        require(_newTotalSupply >= resources[_resourceId].allocatedAmount, "New supply cannot be less than allocated amount");
        
        resources[_resourceId].totalSupply = _newTotalSupply;
        emit ResourceUpdated(_resourceId, _newTotalSupply);
    }

    /**
     * @dev Allocates a resource to a specific RWA asset
     * @param _assetAddress Address of the RWA asset
     * @param _resourceId ID of the resource to allocate
     * @param _amount Amount of the resource to allocate
     */
    function allocateResource(address _assetAddress, uint256 _resourceId, uint256 _amount) public onlyOwner {
        require(resources[_resourceId].isActive, "Resource does not exist");
        require(RWAAsset(_assetAddress).isValidAsset(), "Invalid RWA asset address");
        require(resources[_resourceId].totalSupply.sub(resources[_resourceId].allocatedAmount) >= _amount, "Insufficient resource available");

        resources[_resourceId].allocatedAmount = resources[_resourceId].allocatedAmount.add(_amount);
        assetAllocations[_assetAddress][_resourceId].amount = assetAllocations[_assetAddress][_resourceId].amount.add(_amount);
        assetAllocations[_assetAddress][_resourceId].timestamp = block.timestamp;

        emit ResourceAllocated(_assetAddress, _resourceId, _amount);
    }

    /**
     * @dev Deallocates a resource from a specific RWA asset
     * @param _assetAddress Address of the RWA asset
     * @param _resourceId ID of the resource to deallocate
     * @param _amount Amount of the resource to deallocate
     */
    function deallocateResource(address _assetAddress, uint256 _resourceId, uint256 _amount) public onlyOwner {
        require(resources[_resourceId].isActive, "Resource does not exist");
        require(assetAllocations[_assetAddress][_resourceId].amount >= _amount, "Insufficient allocated amount");

        resources[_resourceId].allocatedAmount = resources[_resourceId].allocatedAmount.sub(_amount);
        assetAllocations[_assetAddress][_resourceId].amount = assetAllocations[_assetAddress][_resourceId].amount.sub(_amount);

        emit ResourceDeallocated(_assetAddress, _resourceId, _amount);
    }

    /**
     * @dev Retrieves the current allocation of a resource for a specific RWA asset
     * @param _assetAddress Address of the RWA asset
     * @param _resourceId ID of the resource
     * @return amount The amount of the resource allocated to the asset
     * @return timestamp The timestamp of the last allocation
     */
    function getResourceAllocation(address _assetAddress, uint256 _resourceId) public view returns (uint256 amount, uint256 timestamp) {
        return (assetAllocations[_assetAddress][_resourceId].amount, assetAllocations[_assetAddress][_resourceId].timestamp);
    }

    /**
     * @dev Retrieves the available amount of a resource
     * @param _resourceId ID of the resource
     * @return The available amount of the resource
     */
    function getAvailableResourceAmount(uint256 _resourceId) public view returns (uint256) {
        require(resources[_resourceId].isActive, "Resource does not exist");
        return resources[_resourceId].totalSupply.sub(resources[_resourceId].allocatedAmount);
    }
}