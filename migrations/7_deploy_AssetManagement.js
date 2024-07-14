const AssetManagement = artifacts.require("AssetManagement");
const RWAAsset = artifacts.require("RWAAsset");
const RWAToken = artifacts.require("RWAToken");
const Compliance = artifacts.require("Compliance");
const OracleIntegration = artifacts.require("OracleIntegration");

module.exports = async function(deployer, network, accounts) {
  // Get the deployed instances of other contracts
  const rwaAsset = await RWAAsset.deployed();
  const rwaToken = await RWAToken.deployed();
  const compliance = await Compliance.deployed();
  const oracleIntegration = await OracleIntegration.deployed();

  // Deploy AssetManagement contract
  await deployer.deploy(
    AssetManagement,
    rwaAsset.address,
    rwaToken.address,
    compliance.address,
    oracleIntegration.address
  );

  // Get the deployed AssetManagement instance
  const assetManagement = await AssetManagement.deployed();

  // Set AssetManagement address in other contracts if necessary
  await rwaAsset.setAssetManagement(assetManagement.address);
  await rwaToken.setAssetManagement(assetManagement.address);
  await compliance.setAssetManagement(assetManagement.address);
  await oracleIntegration.setAssetManagement(assetManagement.address);

  console.log("AssetManagement deployed at:", assetManagement.address);
};