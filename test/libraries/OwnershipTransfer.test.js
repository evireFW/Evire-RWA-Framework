const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("OwnershipTransfer", function () {
  let OwnershipTransfer;
  let owner, addr1, addr2;
  let transferData;
  const assetId = 1;
  const complianceHash = ethers.utils.formatBytes32String("compliance");
  const legalDocumentHash = ethers.utils.formatBytes32String("legal");

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    const OwnershipTransferFactory = await ethers.getContractFactory("OwnershipTransferMock");
    OwnershipTransfer = await OwnershipTransferFactory.deploy();
    await OwnershipTransfer.deployed();

    transferData = {
      from: owner.address,
      to: addr1.address,
      assetId: assetId,
      timestamp: 0,
      status: 0,
      complianceHash: complianceHash,
      legalDocumentHash: legalDocumentHash
    };
  });

  describe("initiateTransfer", function () {
    it("should initiate a transfer", async function () {
      const transferId = await OwnershipTransfer.initiateTransfer(transferData, owner.address, addr1.address, assetId, complianceHash, legalDocumentHash);

      expect(transferData.from).to.equal(owner.address);
      expect(transferData.to).to.equal(addr1.address);
      expect(transferData.assetId).to.equal(assetId);
      expect(transferData.status).to.equal(0);
      expect(transferData.complianceHash).to.equal(complianceHash);
      expect(transferData.legalDocumentHash).to.equal(legalDocumentHash);

      const expectedTransferId = ethers.BigNumber.from(ethers.utils.keccak256(ethers.utils.defaultAbiCoder.encode(
        ['address', 'address', 'uint256', 'uint256'],
        [owner.address, addr1.address, assetId, transferData.timestamp]
      )));
      expect(transferId).to.equal(expectedTransferId);
    });

    it("should emit TransferInitiated event", async function () {
      await expect(OwnershipTransfer.initiateTransfer(transferData, owner.address, addr1.address, assetId, complianceHash, legalDocumentHash))
        .to.emit(OwnershipTransfer, "TransferInitiated")
        .withArgs(ethers.BigNumber.from(ethers.utils.keccak256(ethers.utils.defaultAbiCoder.encode(
          ['address', 'address', 'uint256', 'uint256'],
          [owner.address, addr1.address, assetId, transferData.timestamp]
        ))), owner.address, addr1.address, assetId);
    });

    it("should revert if transferring to self", async function () {
      await expect(OwnershipTransfer.initiateTransfer(transferData, owner.address, owner.address, assetId, complianceHash, legalDocumentHash))
        .to.be.revertedWith("Cannot transfer to self");
    });

    it("should revert if from or to address is zero", async function () {
      await expect(OwnershipTransfer.initiateTransfer(transferData, ethers.constants.AddressZero, addr1.address, assetId, complianceHash, legalDocumentHash))
        .to.be.revertedWith("Invalid addresses");

      await expect(OwnershipTransfer.initiateTransfer(transferData, owner.address, ethers.constants.AddressZero, assetId, complianceHash, legalDocumentHash))
        .to.be.revertedWith("Invalid addresses");
    });
  });

  describe("approveTransfer", function () {
    beforeEach(async function () {
      await OwnershipTransfer.initiateTransfer(transferData, owner.address, addr1.address, assetId, complianceHash, legalDocumentHash);
    });

    it("should approve a transfer", async function () {
      await OwnershipTransfer.approveTransfer(transferData, assetId);

      expect(transferData.status).to.equal(1); // Approved status
    });

    it("should emit TransferApproved event", async function () {
      await expect(OwnershipTransfer.approveTransfer(transferData, assetId))
        .to.emit(OwnershipTransfer, "TransferApproved")
        .withArgs(assetId);
    });

    it("should revert if transfer is not in pending state", async function () {
      transferData.status = 1; // Set status to Approved
      await expect(OwnershipTransfer.approveTransfer(transferData, assetId)).to.be.revertedWith("Transfer not in pending state");
    });
  });

  describe("rejectTransfer", function () {
    beforeEach(async function () {
      await OwnershipTransfer.initiateTransfer(transferData, owner.address, addr1.address, assetId, complianceHash, legalDocumentHash);
    });

    it("should reject a transfer", async function () {
      await OwnershipTransfer.rejectTransfer(transferData, assetId, "Invalid compliance");

      expect(transferData.status).to.equal(2); // Rejected status
    });

    it("should emit TransferRejected event", async function () {
      await expect(OwnershipTransfer.rejectTransfer(transferData, assetId, "Invalid compliance"))
        .to.emit(OwnershipTransfer, "TransferRejected")
        .withArgs(assetId, "Invalid compliance");
    });

    it("should revert if transfer is not in pending state", async function () {
      transferData.status = 1; // Set status to Approved
      await expect(OwnershipTransfer.rejectTransfer(transferData, assetId, "Invalid compliance")).to.be.revertedWith("Transfer not in pending state");
    });
  });

  describe("completeTransfer", function () {
    beforeEach(async function () {
      await OwnershipTransfer.initiateTransfer(transferData, owner.address, addr1.address, assetId, complianceHash, legalDocumentHash);
      await OwnershipTransfer.approveTransfer(transferData, assetId);
    });

    it("should complete a transfer", async function () {
      await OwnershipTransfer.completeTransfer(transferData, assetId);

      expect(transferData.status).to.equal(3); // Completed status
    });

    it("should emit TransferCompleted event", async function () {
      await expect(OwnershipTransfer.completeTransfer(transferData, assetId))
        .to.emit(OwnershipTransfer, "TransferCompleted")
        .withArgs(assetId);
    });

    it("should revert if transfer is not approved", async function () {
      transferData.status = 0; // Set status to Pending
      await expect(OwnershipTransfer.completeTransfer(transferData, assetId)).to.be.revertedWith("Transfer not approved");
    });
  });

  describe("cancelTransfer", function () {
    beforeEach(async function () {
      await OwnershipTransfer.initiateTransfer(transferData, owner.address, addr1.address, assetId, complianceHash, legalDocumentHash);
    });

    it("should cancel a transfer", async function () {
      await OwnershipTransfer.cancelTransfer(transferData, assetId);

      expect(transferData.status).to.equal(4); // Cancelled status
    });

    it("should emit TransferCancelled event", async function () {
      await expect(OwnershipTransfer.cancelTransfer(transferData, assetId))
        .to.emit(OwnershipTransfer, "TransferCancelled")
        .withArgs(assetId);
    });

    it("should revert if transfer is not in pending state", async function () {
      transferData.status = 1; // Set status to Approved
      await expect(OwnershipTransfer.cancelTransfer(transferData, assetId)).to.be.revertedWith("Transfer not in pending state");
    });
  });

  describe("isValidTransfer", function () {
    beforeEach(async function () {
      await OwnershipTransfer.initiateTransfer(transferData, owner.address, addr1.address, assetId, complianceHash, legalDocumentHash);
      await OwnershipTransfer.approveTransfer(transferData, assetId);
    });

    it("should return true for a valid transfer", async function () {
      expect(await OwnershipTransfer.isValidTransfer(transferData)).to.be.true;
    });

    it("should return false for an invalid transfer", async function () {
      transferData.status = 0; // Set status to Pending
      expect(await OwnershipTransfer.isValidTransfer(transferData)).to.be.false;
    });
  });

  describe("getTransferStatus", function () {
    beforeEach(async function () {
      await OwnershipTransfer.initiateTransfer(transferData, owner.address, addr1.address, assetId, complianceHash, legalDocumentHash);
    });

    it("should return the correct transfer status", async function () {
      expect(await OwnershipTransfer.getTransferStatus(transferData)).to.equal(0); // Pending status

      transferData.status = 1; // Set status to Approved
      expect(await OwnershipTransfer.getTransferStatus(transferData)).to.equal(1); // Approved status
    });
  });

  describe("getTimeElapsed", function () {
    beforeEach(async function () {
      await OwnershipTransfer.initiateTransfer(transferData, owner.address, addr1.address, assetId, complianceHash, legalDocumentHash);
    });

    it("should return the time elapsed since the transfer was initiated", async function () {
      const timeElapsed = await OwnershipTransfer.getTimeElapsed(transferData);
      expect(timeElapsed).to.be.gte(0);
    });
  });
});
