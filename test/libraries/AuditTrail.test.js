const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("AuditTrail", function () {
  let AuditTrail;
  let auditTrailStorage;
  let owner, addr1, addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    const AuditTrailFactory = await ethers.getContractFactory("AuditTrail");
    AuditTrail = await AuditTrailFactory.deploy();
    await AuditTrail.deployed();

    auditTrailStorage = {
      entries: {},
      entryCount: ethers.BigNumber.from(0),
      validActions: {},
      authorizedAuditors: {}
    };
  });

  describe("addEntry", function () {
    beforeEach(async function () {
      await AuditTrail.addValidAction(auditTrailStorage, ethers.utils.formatBytes32String("CREATE"));
      await AuditTrail.authorizeAuditor(auditTrailStorage, owner.address);
    });

    it("should add a new audit entry", async function () {
      const action = ethers.utils.formatBytes32String("CREATE");
      const assetId = ethers.utils.formatBytes32String("ASSET123");
      const additionalData = ethers.utils.toUtf8Bytes("Some additional data");

      await AuditTrail.addEntry(auditTrailStorage, addr1.address, action, assetId, additionalData);

      const entry = await AuditTrail.getEntry(auditTrailStorage, 1);
      expect(entry.id).to.equal(1);
      expect(entry.actor).to.equal(addr1.address);
      expect(entry.action).to.equal(action);
      expect(entry.assetId).to.equal(assetId);
      expect(entry.additionalData).to.equal(additionalData);
    });

    it("should emit AuditEntryAdded event", async function () {
      const action = ethers.utils.formatBytes32String("CREATE");
      const assetId = ethers.utils.formatBytes32String("ASSET123");
      const additionalData = ethers.utils.toUtf8Bytes("Some additional data");

      await expect(AuditTrail.addEntry(auditTrailStorage, addr1.address, action, assetId, additionalData))
        .to.emit(AuditTrail, "AuditEntryAdded")
        .withArgs(1, addr1.address, action, assetId);
    });

    it("should revert if the action is invalid", async function () {
      const action = ethers.utils.formatBytes32String("INVALID");
      const assetId = ethers.utils.formatBytes32String("ASSET123");
      const additionalData = ethers.utils.toUtf8Bytes("Some additional data");

      await expect(AuditTrail.addEntry(auditTrailStorage, addr1.address, action, assetId, additionalData))
        .to.be.revertedWith("AuditTrail: Invalid action");
    });

    it("should revert if the caller is not an authorized auditor", async function () {
      await AuditTrail.deauthorizeAuditor(auditTrailStorage, owner.address);

      const action = ethers.utils.formatBytes32String("CREATE");
      const assetId = ethers.utils.formatBytes32String("ASSET123");
      const additionalData = ethers.utils.toUtf8Bytes("Some additional data");

      await expect(AuditTrail.addEntry(auditTrailStorage, addr1.address, action, assetId, additionalData))
        .to.be.revertedWith("AuditTrail: Caller is not an authorized auditor");
    });
  });

  describe("getEntry", function () {
    beforeEach(async function () {
      await AuditTrail.addValidAction(auditTrailStorage, ethers.utils.formatBytes32String("CREATE"));
      await AuditTrail.authorizeAuditor(auditTrailStorage, owner.address);
      await AuditTrail.addEntry(auditTrailStorage, addr1.address, ethers.utils.formatBytes32String("CREATE"), ethers.utils.formatBytes32String("ASSET123"), ethers.utils.toUtf8Bytes("Some additional data"));
    });

    it("should return the correct audit entry", async function () {
      const entry = await AuditTrail.getEntry(auditTrailStorage, 1);
      expect(entry.id).to.equal(1);
      expect(entry.actor).to.equal(addr1.address);
      expect(entry.action).to.equal(ethers.utils.formatBytes32String("CREATE"));
      expect(entry.assetId).to.equal(ethers.utils.formatBytes32String("ASSET123"));
    });

    it("should revert if the entry ID is invalid", async function () {
      await expect(AuditTrail.getEntry(auditTrailStorage, 2)).to.be.revertedWith("AuditTrail: Invalid entry ID");
    });
  });

  describe("addValidAction", function () {
    it("should add a new valid action", async function () {
      const action = ethers.utils.formatBytes32String("UPDATE");
      await AuditTrail.addValidAction(auditTrailStorage, action);
      expect(await AuditTrail.isValidAction(auditTrailStorage, action)).to.be.true;
    });

    it("should emit ActionAdded event", async function () {
      const action = ethers.utils.formatBytes32String("UPDATE");
      await expect(AuditTrail.addValidAction(auditTrailStorage, action))
        .to.emit(AuditTrail, "ActionAdded")
        .withArgs(action);
    });

    it("should revert if the action already exists", async function () {
      const action = ethers.utils.formatBytes32String("UPDATE");
      await AuditTrail.addValidAction(auditTrailStorage, action);
      await expect(AuditTrail.addValidAction(auditTrailStorage, action)).to.be.revertedWith("AuditTrail: Action already exists");
    });
  });

  describe("removeValidAction", function () {
    beforeEach(async function () {
      await AuditTrail.addValidAction(auditTrailStorage, ethers.utils.formatBytes32String("DELETE"));
    });

    it("should remove a valid action", async function () {
      const action = ethers.utils.formatBytes32String("DELETE");
      await AuditTrail.removeValidAction(auditTrailStorage, action);
      expect(await AuditTrail.isValidAction(auditTrailStorage, action)).to.be.false;
    });

    it("should emit ActionRemoved event", async function () {
      const action = ethers.utils.formatBytes32String("DELETE");
      await expect(AuditTrail.removeValidAction(auditTrailStorage, action))
        .to.emit(AuditTrail, "ActionRemoved")
        .withArgs(action);
    });

    it("should revert if the action does not exist", async function () {
      const action = ethers.utils.formatBytes32String("NON_EXISTENT");
      await expect(AuditTrail.removeValidAction(auditTrailStorage, action)).to.be.revertedWith("AuditTrail: Action does not exist");
    });
  });

  describe("authorizeAuditor", function () {
    it("should authorize a new auditor", async function () {
      await AuditTrail.authorizeAuditor(auditTrailStorage, addr1.address);
      expect(await AuditTrail.isAuthorizedAuditor(auditTrailStorage, addr1.address)).to.be.true;
    });

    it("should emit AuditorAuthorized event", async function () {
      await expect(AuditTrail.authorizeAuditor(auditTrailStorage, addr1.address))
        .to.emit(AuditTrail, "AuditorAuthorized")
        .withArgs(addr1.address);
    });

    it("should revert if the auditor is already authorized", async function () {
      await AuditTrail.authorizeAuditor(auditTrailStorage, addr1.address);
      await expect(AuditTrail.authorizeAuditor(auditTrailStorage, addr1.address)).to.be.revertedWith("AuditTrail: Auditor already authorized");
    });
  });

  describe("deauthorizeAuditor", function () {
    beforeEach(async function () {
      await AuditTrail.authorizeAuditor(auditTrailStorage, addr1.address);
    });

    it("should deauthorize an existing auditor", async function () {
      await AuditTrail.deauthorizeAuditor(auditTrailStorage, addr1.address);
      expect(await AuditTrail.isAuthorizedAuditor(auditTrailStorage, addr1.address)).to.be.false;
    });

    it("should emit AuditorDeauthorized event", async function () {
      await expect(AuditTrail.deauthorizeAuditor(auditTrailStorage, addr1.address))
        .to.emit(AuditTrail, "AuditorDeauthorized")
        .withArgs(addr1.address);
    });

    it("should revert if the auditor is not authorized", async function () {
      await AuditTrail.deauthorizeAuditor(auditTrailStorage, addr1.address);
      await expect(AuditTrail.deauthorizeAuditor(auditTrailStorage, addr1.address)).to.be.revertedWith("AuditTrail: Auditor not authorized");
    });
  });

  describe("isValidAction", function () {
    it("should return true for a valid action", async function () {
      const action = ethers.utils.formatBytes32String("VALID_ACTION");
      await AuditTrail.addValidAction(auditTrailStorage, action);
      expect(await AuditTrail.isValidAction(auditTrailStorage, action)).to.be.true;
    });

    it("should return false for an invalid action", async function () {
      const action = ethers.utils.formatBytes32String("INVALID_ACTION");
      expect(await AuditTrail.isValidAction(auditTrailStorage, action)).to.be.false;
    });
  });

  describe("isAuthorizedAuditor", function () {
    it("should return true for an authorized auditor", async function () {
      await AuditTrail.authorizeAuditor(auditTrailStorage, addr1.address);
      expect(await AuditTrail.isAuthorizedAuditor(auditTrailStorage, addr1.address)).to.be.true;
    });

    it("should return false for a non-authorized auditor", async function () {
      expect(await AuditTrail.isAuthorizedAuditor(auditTrailStorage, addr1.address)).to.be.false;
    });
  });

  describe("getEntryCount", function () {
    it("should return the correct number of entries", async function () {
      await AuditTrail.addValidAction(auditTrailStorage, ethers.utils.formatBytes32String("CREATE"));
      await AuditTrail.authorizeAuditor(auditTrailStorage, owner.address);
      await AuditTrail.addEntry(auditTrailStorage, addr1.address, ethers.utils.formatBytes32String("CREATE"), ethers.utils.formatBytes32String("ASSET123"), ethers.utils.toUtf8Bytes("Some additional data"));
      expect(await AuditTrail.getEntryCount(auditTrailStorage)).to.equal(1);
    });
  });

  describe("getEntryRange", function () {
    beforeEach(async function () {
      await AuditTrail.addValidAction(auditTrailStorage, ethers.utils.formatBytes32String("CREATE"));
      await AuditTrail.authorizeAuditor(auditTrailStorage, owner.address);
      await AuditTrail.addEntry(auditTrailStorage, addr1.address, ethers.utils.formatBytes32String("CREATE"), ethers.utils.formatBytes32String("ASSET123"), ethers.utils.toUtf8Bytes("Some additional data"));
      await AuditTrail.addEntry(auditTrailStorage, addr2.address, ethers.utils.formatBytes32String("CREATE"), ethers.utils.formatBytes32String("ASSET456"), ethers.utils.toUtf8Bytes("More data"));
    });

    it("should return the correct range of entries", async function () {
      const entries = await AuditTrail.getEntryRange(auditTrailStorage, 1, 2);
      expect(entries.length).to.equal(2);
      expect(entries[0].id).to.equal(1);
      expect(entries[1].id).to.equal(2);
    });

    it("should revert if startId is invalid", async function () {
      await expect(AuditTrail.getEntryRange(auditTrailStorage, 0, 2)).to.be.revertedWith("AuditTrail: Invalid start ID");
    });

    it("should revert if endId is invalid", async function () {
      await expect(AuditTrail.getEntryRange(auditTrailStorage, 1, 3)).to.be.revertedWith("AuditTrail: Invalid end ID");
    });
  });
});
