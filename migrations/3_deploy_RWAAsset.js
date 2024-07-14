const RWAAsset = artifacts.require("RWAAsset");
const AssetValuation = artifacts.require("AssetValuation");
const DataVerification = artifacts.require("DataVerification");

module.exports = async function(deployer, network, accounts) {
  // Deploy AssetValuation library if not already deployed
  await deployer.deploy(AssetValuation);
  
  // Deploy DataVerification library if not already deployed
  await deployer.deploy(DataVerification);

  // Link libraries to RWAAsset contract
  await deployer.link(AssetValuation, RWAAsset);
  await deployer.link(DataVerification, RWAAsset);

  // Deploy RWAAsset contract
  const owner = accounts[0]; // Assuming the first account is the owner
  const assetName = "Example Real World Asset";
  const assetSymbol = "ERWA";
  const initialSupply = web3.utils.toWei("1000000", "ether"); // 1 million tokens

  await deployer.deploy(RWAAsset, assetName, assetSymbol, initialSupply, owner);
};