const AssetValuation = artifacts.require("AssetValuation");
const ComplianceChecks = artifacts.require("ComplianceChecks");
const DataVerification = artifacts.require("DataVerification");
const OwnershipTransfer = artifacts.require("OwnershipTransfer");
const AssetTokenization = artifacts.require("AssetTokenization");
const RiskAssessment = artifacts.require("RiskAssessment");
const AuditTrail = artifacts.require("AuditTrail");

module.exports = function(deployer) {
  deployer.deploy(AssetValuation);
  deployer.deploy(ComplianceChecks);
  deployer.deploy(DataVerification);
  deployer.deploy(OwnershipTransfer);
  deployer.deploy(AssetTokenization);
  deployer.deploy(RiskAssessment);
  deployer.deploy(AuditTrail);
};