const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ResourceAllocation", function () {
  let ResourceAllocation, resourceAllocation;
  let RWAAsset, rwaAsset;
  let owner, addr1, addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    // Deploy the RWAAsset contract first
    RWAAsset = await ethers.getContractFactory("RWAAsset");
    rwaAsset = await RWAAsset.deploy();
    await rwaAsset.deployed();

    // Deploy the ResourceAllocation contract
    ResourceAllocation = await ethers.getContractFactory("ResourceAllocation");
    resourceAllocation = await ResourceAllocation.deploy();
    await resourceAllocation.deployed();
  });

  describe("Resource management", function () {
    it("should allow the owner to add a new resource", async function () {
      const resourceName = "Electricity";
      const totalSupply = ethers.utils.parseEther("1000");

      await resourceAllocation.addResource(resourceName, totalSupply);

      const resource = await resourceAllocation.resources(1);
      expect(resource.name).to.equal(resourceName);
      expect(resource.totalSupply.toString()).to.equal(totalSupply.toString());
      expect(resource.allocatedAmount.toString()).to.equal("0");
      expect(resource.isActive).to.be.true;
    });

    it("should emit ResourceAdded event when a new resource is added", async function () {
      const resourceName = "Electricity";
      const totalSupply = ethers.utils.parseEther("1000");

      await expect(resourceAllocation.addResource(resourceName, totalSupply))
        .to.emit(resourceAllocation, "ResourceAdded")
        .withArgs(1, resourceName, totalSupply);
    });

    it("should allow the owner to update the total supply of a resource", async function () {
      const resourceName = "Electricity";
      const totalSupply = ethers.utils.parseEther("1000");
      const newTotalSupply = ethers.utils.parseEther("2000");

      await resourceAllocation.addResource(resourceName, totalSupply);
      await resourceAllocation.updateResourceSupply(1, newTotalSupply);

      const resource = await resourceAllocation.resources(1);
      expect(resource.totalSupply.toString()).to.equal(newTotalSupply.toString());
    });

    it("should emit ResourceUpdated event when a resource supply is updated", async function () {
      const resourceName = "Electricity";
      const totalSupply = ethers.utils.parseEther("1000");
      const newTotalSupply = ethers.utils.parseEther("2000");

      await resourceAllocation.addResource(resourceName, totalSupply);

      await expect(resourceAllocation.updateResourceSupply(1, newTotalSupply))
        .to.emit(resourceAllocation, "ResourceUpdated")
        .withArgs(1, newTotalSupply);
    });

    it("should revert if updating resource supply to less than allocated amount", async function () {
      const resourceName = "Electricity";
      const totalSupply = ethers.utils.parseEther("1000");
      const allocatedAmount = ethers.utils.parseEther("500");

      await resourceAllocation.addResource(resourceName, totalSupply);
      await resourceAllocation.allocateResource(owner.address, 1, allocatedAmount);

      await expect(resourceAllocation.updateResourceSupply(1, ethers.utils.parseEther("400")))
        .to.be.revertedWith("New supply cannot be less than allocated amount");
    });
  });

  describe("Resource allocation", function () {
    beforeEach(async function () {
      const resourceName = "Electricity";
      const totalSupply = ethers.utils.parseEther("1000");
      await resourceAllocation.addResource(resourceName, totalSupply);

      // Mint a valid RWA asset
      await rwaAsset.mint(owner.address, 1);
    });

    it("should allow the owner to allocate a resource to a valid RWA asset", async function () {
      const allocationAmount = ethers.utils.parseEther("100");

      await resourceAllocation.allocateResource(owner.address, 1, allocationAmount);

      const resource = await resourceAllocation.resources(1);
      expect(resource.allocatedAmount.toString()).to.equal(allocationAmount.toString());

      const allocation = await resourceAllocation.getResourceAllocation(owner.address, 1);
      expect(allocation.amount.toString()).to.equal(allocationAmount.toString());
    });

    it("should emit ResourceAllocated event when a resource is allocated", async function () {
      const allocationAmount = ethers.utils.parseEther("100");

      await expect(resourceAllocation.allocateResource(owner.address, 1, allocationAmount))
        .to.emit(resourceAllocation, "ResourceAllocated")
        .withArgs(owner.address, 1, allocationAmount);
    });

    it("should revert if allocating more than available resource amount", async function () {
      const allocationAmount = ethers.utils.parseEther("1100");

      await expect(resourceAllocation.allocateResource(owner.address, 1, allocationAmount))
        .to.be.revertedWith("Insufficient resource available");
    });

    it("should revert if allocating a resource to an invalid RWA asset", async function () {
      const allocationAmount = ethers.utils.parseEther("100");

      await expect(resourceAllocation.allocateResource(addr1.address, 1, allocationAmount))
        .to.be.revertedWith("Invalid RWA asset address");
    });
  });

  describe("Resource deallocation", function () {
    beforeEach(async function () {
      const resourceName = "Electricity";
      const totalSupply = ethers.utils.parseEther("1000");
      await resourceAllocation.addResource(resourceName, totalSupply);

      // Mint a valid RWA asset
      await rwaAsset.mint(owner.address, 1);

      // Allocate some resource
      await resourceAllocation.allocateResource(owner.address, 1, ethers.utils.parseEther("100"));
    });

    it("should allow the owner to deallocate a resource from a valid RWA asset", async function () {
      const deallocationAmount = ethers.utils.parseEther("50");

      await resourceAllocation.deallocateResource(owner.address, 1, deallocationAmount);

      const resource = await resourceAllocation.resources(1);
      expect(resource.allocatedAmount.toString()).to.equal(ethers.utils.parseEther("50").toString());

      const allocation = await resourceAllocation.getResourceAllocation(owner.address, 1);
      expect(allocation.amount.toString()).to.equal(ethers.utils.parseEther("50").toString());
    });

    it("should emit ResourceDeallocated event when a resource is deallocated", async function () {
      const deallocationAmount = ethers.utils.parseEther("50");

      await expect(resourceAllocation.deallocateResource(owner.address, 1, deallocationAmount))
        .to.emit(resourceAllocation, "ResourceDeallocated")
        .withArgs(owner.address, 1, deallocationAmount);
    });

    it("should revert if deallocating more than allocated amount", async function () {
      const deallocationAmount = ethers.utils.parseEther("200");

      await expect(resourceAllocation.deallocateResource(owner.address, 1, deallocationAmount))
        .to.be.revertedWith("Insufficient allocated amount");
    });
  });

  describe("Resource allocation details", function () {
    beforeEach(async function () {
      const resourceName = "Electricity";
      const totalSupply = ethers.utils.parseEther("1000");
      await resourceAllocation.addResource(resourceName, totalSupply);

      // Mint a valid RWA asset
      await rwaAsset.mint(owner.address, 1);

      // Allocate some resource
      await resourceAllocation.allocateResource(owner.address, 1, ethers.utils.parseEther("100"));
    });

    it("should return the current allocation of a resource for a specific RWA asset", async function () {
      const allocation = await resourceAllocation.getResourceAllocation(owner.address, 1);
      expect(allocation.amount.toString()).to.equal(ethers.utils.parseEther("100").toString());
    });

    it("should return the available amount of a resource", async function () {
      const availableAmount = await resourceAllocation.getAvailableResourceAmount(1);
      expect(availableAmount.toString()).to.equal(ethers.utils.parseEther("900").toString());
    });

    it("should revert if querying available amount of a non-existent resource", async function () {
      await expect(resourceAllocation.getAvailableResourceAmount(2))
        .to.be.revertedWith("Resource does not exist");
    });
  });
});
