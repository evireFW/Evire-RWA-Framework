const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Compliance", function () {
  let Compliance, compliance;
  let owner, addr1, addr2;
  
  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    // Deploy the Compliance contract
    Compliance = await ethers.getContractFactory("Compliance");
    compliance = await Compliance.deploy();
    await compliance.deployed();
  });

  describe("Rule management", function () {
    it("should initialize with a default rule", async function () {
      const ruleCount = await compliance.getRuleCount();
      expect(ruleCount).to.equal(1);

      const rule = await compliance.rules(0);
      expect(rule.name).to.equal("KYC");
      expect(rule.description).to.equal("Know Your Customer verification");
      expect(rule.isActive).to.be.true;
    });

    it("should allow the owner to add a new rule", async function () {
      await compliance.addRule("AML", "Anti-Money Laundering check");
      const ruleCount = await compliance.getRuleCount();
      expect(ruleCount).to.equal(2);

      const rule = await compliance.rules(1);
      expect(rule.name).to.equal("AML");
      expect(rule.description).to.equal("Anti-Money Laundering check");
      expect(rule.isActive).to.be.true;
    });

    it("should emit RuleAdded event when a new rule is added", async function () {
      await expect(compliance.addRule("AML", "Anti-Money Laundering check"))
        .to.emit(compliance, "RuleAdded")
        .withArgs(1, "AML");
    });

    it("should allow the owner to update a rule's active status", async function () {
      await compliance.updateRule(0, false);
      const rule = await compliance.rules(0);
      expect(rule.isActive).to.be.false;
    });

    it("should emit RuleUpdated event when a rule is updated", async function () {
      await expect(compliance.updateRule(0, false))
        .to.emit(compliance, "RuleUpdated")
        .withArgs(0, "KYC", false);
    });

    it("should revert if updating a non-existent rule", async function () {
      await expect(compliance.updateRule(10, true)).to.be.revertedWith("Rule does not exist");
    });
  });

  describe("Address whitelisting and blacklisting", function () {
    it("should allow the owner to whitelist an address", async function () {
      await compliance.whitelistAddress(addr1.address);
      expect(await compliance.whitelistedAddresses(addr1.address)).to.be.true;
    });

    it("should emit AddressWhitelisted event when an address is whitelisted", async function () {
      await expect(compliance.whitelistAddress(addr1.address))
        .to.emit(compliance, "AddressWhitelisted")
        .withArgs(addr1.address);
    });

    it("should allow the owner to blacklist an address", async function () {
      await compliance.whitelistAddress(addr1.address);
      await compliance.blacklistAddress(addr1.address);
      expect(await compliance.whitelistedAddresses(addr1.address)).to.be.false;
    });

    it("should emit AddressBlacklisted event when an address is blacklisted", async function () {
      await expect(compliance.blacklistAddress(addr1.address))
        .to.emit(compliance, "AddressBlacklisted")
        .withArgs(addr1.address);
    });
  });

  describe("Address compliance", function () {
    beforeEach(async function () {
      await compliance.whitelistAddress(addr1.address);
      await compliance.addRule("AML", "Anti-Money Laundering check");
    });

    it("should allow the owner to update address compliance for a rule", async function () {
      await compliance.updateAddressCompliance(addr1.address, 1, true);
      expect(await compliance.addressCompliance(addr1.address, 1)).to.be.true;
    });

    it("should emit ComplianceUpdated event when address compliance is updated", async function () {
      await expect(compliance.updateAddressCompliance(addr1.address, 1, true))
        .to.emit(compliance, "ComplianceUpdated")
        .withArgs(addr1.address, 1, true);
    });

    it("should revert if updating compliance for a non-existent rule", async function () {
      await expect(compliance.updateAddressCompliance(addr1.address, 10, true)).to.be.revertedWith("Rule does not exist");
    });
  });

  describe("Compliance check", function () {
    beforeEach(async function () {
      await compliance.whitelistAddress(addr1.address);
      await compliance.addRule("AML", "Anti-Money Laundering check");
    });

    it("should return true if an address is compliant with all active rules", async function () {
      await compliance.updateAddressCompliance(addr1.address, 1, true);
      expect(await compliance.isCompliant(addr1.address)).to.be.true;
    });

    it("should return false if an address is not whitelisted", async function () {
      expect(await compliance.isCompliant(addr2.address)).to.be.false;
    });

    it("should return false if an address is not compliant with an active rule", async function () {
      expect(await compliance.isCompliant(addr1.address)).to.be.false;
    });
  });
});
