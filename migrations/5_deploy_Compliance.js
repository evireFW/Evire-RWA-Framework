const Compliance = artifacts.require("Compliance");
const RWAAsset = artifacts.require("RWAAsset");
const RWAToken = artifacts.require("RWAToken");
const ComplianceChecks = artifacts.require("ComplianceChecks");

module.exports = async function(deployer, network, accounts) {
  // Deploy ComplianceChecks library if not already deployed
  await deployer.deploy(ComplianceChecks);
  
  // Link ComplianceChecks library to Compliance contract
  await deployer.link(ComplianceChecks, Compliance);

  // Get deployed instances of RWAAsset and RWAToken
  const rwaAsset = await RWAAsset.deployed();
  const rwaToken = await RWAToken.deployed();

  // Deploy Compliance contract
  await deployer.deploy(Compliance, rwaAsset.address, rwaToken.address);
  
  const compliance = await Compliance.deployed();

  // Set Compliance contract address in RWAAsset and RWAToken
  await rwaAsset.setComplianceContract(compliance.address);
  await rwaToken.setComplianceContract(compliance.address);
};