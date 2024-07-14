const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ComplianceChecks", function () {
  let ComplianceChecks;
  let complianceData;
  let owner, addr1, addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    const ComplianceChecksFactory = await ethers.getContractFactory("ComplianceChecksMock");
    ComplianceChecks = await ComplianceChecksFactory.deploy();
    await ComplianceChecks.deployed();

    complianceData = {
      kycApproved: {},
      accreditedInvestor: {},
      investorRiskScore: {},
      lastComplianceCheck: {},
      blacklistedAddresses: new Set(),
      jurisdictionApproval: {},
      maxInvestorCount: 100,
      minHoldingPeriod: 86400,
      maxInvestmentAmount: ethers.utils.parseEther("1000"),
      complianceManager: owner.address,
      restrictedTransfer: false
    };
  });

  describe("initialize", function () {
    it("should initialize compliance data correctly", async function () {
      await ComplianceChecks.initialize(
        complianceData,
        owner.address,
        100,
        86400,
        ethers.utils.parseEther("1000"),
        true
      );

      expect(complianceData.complianceManager).to.equal(owner.address);
      expect(complianceData.maxInvestorCount).to.equal(100);
      expect(complianceData.minHoldingPeriod).to.equal(86400);
      expect(complianceData.maxInvestmentAmount).to.equal(ethers.utils.parseEther("1000"));
      expect(complianceData.restrictedTransfer).to.be.true;
    });
  });

  describe("KYC Approval", function () {
    it("should set and check KYC approval status", async function () {
      await ComplianceChecks.setKYCApproval(complianceData, addr1.address, true);
      expect(await ComplianceChecks.isKYCApproved(complianceData, addr1.address)).to.be.true;

      await ComplianceChecks.setKYCApproval(complianceData, addr1.address, false);
      expect(await ComplianceChecks.isKYCApproved(complianceData, addr1.address)).to.be.false;
    });
  });

  describe("Accredited Investor", function () {
    it("should set and check accredited investor status", async function () {
      await ComplianceChecks.setAccreditedInvestorStatus(complianceData, addr1.address, true);
      expect(await ComplianceChecks.isAccreditedInvestor(complianceData, addr1.address)).to.be.true;

      await ComplianceChecks.setAccreditedInvestorStatus(complianceData, addr1.address, false);
      expect(await ComplianceChecks.isAccreditedInvestor(complianceData, addr1.address)).to.be.false;
    });
  });

  describe("Blacklist", function () {
    it("should add and remove addresses from blacklist", async function () {
      await ComplianceChecks.addToBlacklist(complianceData, addr1.address);
      expect(await ComplianceChecks.isBlacklisted(complianceData, addr1.address)).to.be.true;

      await ComplianceChecks.removeFromBlacklist(complianceData, addr1.address);
      expect(await ComplianceChecks.isBlacklisted(complianceData, addr1.address)).to.be.false;
    });
  });

  describe("Jurisdiction Approval", function () {
    const jurisdiction = ethers.utils.formatBytes32String("US");

    it("should set and check jurisdiction approval", async function () {
      await ComplianceChecks.setJurisdictionApproval(complianceData, addr1.address, jurisdiction, true);
      expect(await ComplianceChecks.isApprovedForJurisdiction(complianceData, addr1.address, jurisdiction)).to.be.true;

      await ComplianceChecks.setJurisdictionApproval(complianceData, addr1.address, jurisdiction, false);
      expect(await ComplianceChecks.isApprovedForJurisdiction(complianceData, addr1.address, jurisdiction)).to.be.false;
    });
  });

  describe("Risk Score", function () {
    it("should update and retrieve risk score", async function () {
      await ComplianceChecks.updateRiskScore(complianceData, addr1.address, 50);
      expect(await ComplianceChecks.investorRiskScore(complianceData, addr1.address)).to.equal(50);

      await ComplianceChecks.updateRiskScore(complianceData, addr1.address, 75);
      expect(await ComplianceChecks.investorRiskScore(complianceData, addr1.address)).to.equal(75);
    });
  });

  describe("Compliance Check", function () {
    it("should perform compliance check and return true if compliant", async function () {
      await ComplianceChecks.setKYCApproval(complianceData, addr1.address, true);
      await ComplianceChecks.updateRiskScore(complianceData, addr1.address, 50);

      const isCompliant = await ComplianceChecks.performComplianceCheck(complianceData, addr1.address);
      expect(isCompliant).to.be.true;
    });

    it("should perform compliance check and return false if not compliant", async function () {
      await ComplianceChecks.setKYCApproval(complianceData, addr1.address, false);
      await ComplianceChecks.updateRiskScore(complianceData, addr1.address, 50);

      const isCompliant = await ComplianceChecks.performComplianceCheck(complianceData, addr1.address);
      expect(isCompliant).to.be.false;
    });
  });

  describe("Transfer Compliance", function () {
    it("should check if transfer is compliant", async function () {
      await ComplianceChecks.setKYCApproval(complianceData, addr2.address, true);
      const isCompliant = await ComplianceChecks.isTransferCompliant(complianceData, addr1.address, addr2.address, ethers.utils.parseEther("500"));
      expect(isCompliant).to.be.true;
    });

    it("should revert if transfer amount exceeds maximum allowed", async function () {
      await ComplianceChecks.setKYCApproval(complianceData, addr2.address, true);
      await expect(
        ComplianceChecks.isTransferCompliant(complianceData, addr1.address, addr2.address, ethers.utils.parseEther("1500"))
      ).to.be.revertedWith("Transfer amount exceeds maximum allowed");
    });

    it("should revert if recipient is not KYC approved", async function () {
      await ComplianceChecks.setKYCApproval(complianceData, addr2.address, false);
      await expect(
        ComplianceChecks.isTransferCompliant(complianceData, addr1.address, addr2.address, ethers.utils.parseEther("500"))
      ).to.be.revertedWith("Recipient is not KYC approved");
    });
  });

  describe("Minimum Holding Period", function () {
    it("should check if minimum holding period has passed", async function () {
      const initialTime = (await ethers.provider.getBlock('latest')).timestamp;
      expect(await ComplianceChecks.hasMinHoldingPeriodPassed(complianceData, addr1.address, initialTime - 90000)).to.be.true;
      expect(await ComplianceChecks.hasMinHoldingPeriodPassed(complianceData, addr1.address, initialTime - 80000)).to.be.false;
    });
  });

  describe("Investor Count", function () {
    it("should check if adding a new investor is allowed", async function () {
      expect(await ComplianceChecks.canAddNewInvestor(complianceData, 99)).to.be.true;
      expect(await ComplianceChecks.canAddNewInvestor(complianceData, 100)).to.be.false;
    });
  });
});
