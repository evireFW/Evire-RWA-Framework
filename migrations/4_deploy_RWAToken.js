const RWAToken = artifacts.require("RWAToken");
const RWAAsset = artifacts.require("RWAAsset");

module.exports = async function(deployer, network, accounts) {
  const rwsAssetInstance = await RWAAsset.deployed();

  await deployer.deploy(RWAToken, rwsAssetInstance.address);
  const rwaTokenInstance = await RWAToken.deployed();

  // Set the RWAToken address in the RWAAsset contract
  await rwsAssetInstance.setRWATokenAddress(rwaTokenInstance.address);

  console.log("RWAToken deployed at:", rwaTokenInstance.address);
};