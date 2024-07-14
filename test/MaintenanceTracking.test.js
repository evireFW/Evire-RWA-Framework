const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MaintenanceTracking", function () {
  let MaintenanceTracking, maintenanceTracking;
  let RWAAsset, rwaAsset;
  let owner, addr1, addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    // Deploy the RWAAsset contract first
    RWAAsset = await ethers.getContractFactory("RWAAsset");
    rwaAsset = await RWAAsset.deploy();
    await rwaAsset.deployed();

    // Deploy the MaintenanceTracking contract with the address of the RWAAsset contract
    MaintenanceTracking = await ethers.getContractFactory("MaintenanceTracking");
    maintenanceTracking = await MaintenanceTracking.deploy(rwaAsset.address);
    await maintenanceTracking.deployed();
  });

  describe("Schedule maintenance", function () {
    it("should allow the owner to schedule maintenance for an existing asset", async function () {
      const assetId = 1;
      const description = "General maintenance";

      await rwaAsset.mint(owner.address, assetId);
      await maintenanceTracking.scheduleMaintenance(assetId, description);

      const maintenanceHistory = await maintenanceTracking.getAssetMaintenanceHistory(assetId);
      expect(maintenanceHistory.length).to.equal(1);

      const maintenanceId = maintenanceHistory[0];
      const maintenanceRecord = await maintenanceTracking.getMaintenanceDetails(maintenanceId);
      expect(maintenanceRecord.assetId).to.equal(assetId);
      expect(maintenanceRecord.description).to.equal(description);
      expect(maintenanceRecord.isCompleted).to.be.false;
    });

    it("should emit MaintenanceScheduled event when maintenance is scheduled", async function () {
      const assetId = 1;
      const description = "General maintenance";

      await rwaAsset.mint(owner.address, assetId);

      await expect(maintenanceTracking.scheduleMaintenance(assetId, description))
        .to.emit(maintenanceTracking, "MaintenanceScheduled")
        .withArgs(1, assetId, description);
    });

    it("should revert if scheduling maintenance for a non-existent asset", async function () {
      const assetId = 1;
      const description = "General maintenance";

      await expect(maintenanceTracking.scheduleMaintenance(assetId, description)).to.be.revertedWith("Asset does not exist");
    });
  });

  describe("Complete maintenance", function () {
    let assetId;
    let maintenanceId;

    beforeEach(async function () {
      assetId = 1;
      await rwaAsset.mint(owner.address, assetId);
      await maintenanceTracking.scheduleMaintenance(assetId, "General maintenance");
      const maintenanceHistory = await maintenanceTracking.getAssetMaintenanceHistory(assetId);
      maintenanceId = maintenanceHistory[0];
    });

    it("should allow the asset owner to complete scheduled maintenance", async function () {
      const cost = ethers.utils.parseEther("10");

      await maintenanceTracking.connect(owner).completeMaintenance(maintenanceId, cost);

      const maintenanceRecord = await maintenanceTracking.getMaintenanceDetails(maintenanceId);
      expect(maintenanceRecord.isCompleted).to.be.true;
      expect(maintenanceRecord.cost.toString()).to.equal(cost.toString());
      expect(maintenanceRecord.performedBy).to.equal(owner.address);
    });

    it("should emit MaintenanceCompleted event when maintenance is completed", async function () {
      const cost = ethers.utils.parseEther("10");

      await expect(maintenanceTracking.connect(owner).completeMaintenance(maintenanceId, cost))
        .to.emit(maintenanceTracking, "MaintenanceCompleted")
        .withArgs(maintenanceId, assetId, owner.address, cost);
    });

    it("should revert if trying to complete already completed maintenance", async function () {
      const cost = ethers.utils.parseEther("10");
      await maintenanceTracking.connect(owner).completeMaintenance(maintenanceId, cost);

      await expect(maintenanceTracking.connect(owner).completeMaintenance(maintenanceId, cost))
        .to.be.revertedWith("Maintenance already completed");
    });

    it("should revert if non-owner tries to complete maintenance", async function () {
      const cost = ethers.utils.parseEther("10");

      await expect(maintenanceTracking.connect(addr1).completeMaintenance(maintenanceId, cost))
        .to.be.revertedWith("Only asset owner can complete maintenance");
    });
  });

  describe("View maintenance history", function () {
    it("should return the maintenance history for an asset", async function () {
      const assetId = 1;
      await rwaAsset.mint(owner.address, assetId);
      await maintenanceTracking.scheduleMaintenance(assetId, "First maintenance");
      await maintenanceTracking.scheduleMaintenance(assetId, "Second maintenance");

      const maintenanceHistory = await maintenanceTracking.getAssetMaintenanceHistory(assetId);
      expect(maintenanceHistory.length).to.equal(2);
    });

    it("should return the details of a specific maintenance record", async function () {
      const assetId = 1;
      await rwaAsset.mint(owner.address, assetId);
      await maintenanceTracking.scheduleMaintenance(assetId, "General maintenance");

      const maintenanceHistory = await maintenanceTracking.getAssetMaintenanceHistory(assetId);
      const maintenanceId = maintenanceHistory[0];
      const maintenanceRecord = await maintenanceTracking.getMaintenanceDetails(maintenanceId);

      expect(maintenanceRecord.assetId).to.equal(assetId);
      expect(maintenanceRecord.description).to.equal("General maintenance");
    });
  });
});
