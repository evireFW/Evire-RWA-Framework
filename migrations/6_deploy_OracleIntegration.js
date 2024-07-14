const OracleIntegration = artifacts.require("OracleIntegration");
const RWAAsset = artifacts.require("RWAAsset");
const RWAToken = artifacts.require("RWAToken");
const Compliance = artifacts.require("Compliance");

module.exports = async function(deployer, network, accounts) {
  const rwaAsset = await RWAAsset.deployed();
  const rwaToken = await RWAToken.deployed();
  const compliance = await Compliance.deployed();

  // Deploy OracleIntegration
  await deployer.deploy(OracleIntegration, rwaAsset.address, rwaToken.address, compliance.address);
  const oracleIntegration = await OracleIntegration.deployed();

  // Set OracleIntegration address in other contracts if necessary
  await rwaAsset.setOracleIntegration(oracleIntegration.address);
  await rwaToken.setOracleIntegration(oracleIntegration.address);
  await compliance.setOracleIntegration(oracleIntegration.address);

  console.log("OracleIntegration deployed at:", oracleIntegration.address);
};