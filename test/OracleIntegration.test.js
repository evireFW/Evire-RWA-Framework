const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("OracleIntegration", function () {
  let OracleIntegration;
  let oracleIntegration;
  let owner;
  let addr1;

  const dataType = ethers.utils.formatBytes32String("price");
  const newDataType = ethers.utils.formatBytes32String("weather");
  const initialOracleAddress = "0x0000000000000000000000000000000000000001";
  const updatedOracleAddress = "0x0000000000000000000000000000000000000002";

  beforeEach(async function () {
    OracleIntegration = await ethers.getContractFactory("OracleIntegration");
    [owner, addr1] = await ethers.getSigners();
    oracleIntegration = await OracleIntegration.deploy();
    await oracleIntegration.deployed();
  });

  describe("Add Oracle", function () {
    it("should allow the owner to add an oracle", async function () {
      await oracleIntegration.addOracle(dataType, initialOracleAddress);
      expect(await oracleIntegration.getOracleAddress(dataType)).to.equal(initialOracleAddress);
    });

    it("should emit an OracleAdded event when an oracle is added", async function () {
      await expect(oracleIntegration.addOracle(dataType, initialOracleAddress))
        .to.emit(oracleIntegration, "OracleAdded")
        .withArgs(dataType, initialOracleAddress);
    });

    it("should revert if an oracle for the data type already exists", async function () {
      await oracleIntegration.addOracle(dataType, initialOracleAddress);
      await expect(oracleIntegration.addOracle(dataType, updatedOracleAddress)).to.be.revertedWith("Oracle already exists for this data type");
    });

    it("should revert if a non-owner tries to add an oracle", async function () {
      await expect(oracleIntegration.connect(addr1).addOracle(dataType, initialOracleAddress)).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("should revert if the oracle address is invalid", async function () {
      await expect(oracleIntegration.addOracle(dataType, ethers.constants.AddressZero)).to.be.revertedWith("Invalid oracle address");
    });
  });

  describe("Update Oracle", function () {
    beforeEach(async function () {
      await oracleIntegration.addOracle(dataType, initialOracleAddress);
    });

    it("should allow the owner to update an oracle", async function () {
      await oracleIntegration.updateOracle(dataType, updatedOracleAddress);
      expect(await oracleIntegration.getOracleAddress(dataType)).to.equal(updatedOracleAddress);
    });

    it("should emit an OracleUpdated event when an oracle is updated", async function () {
      await expect(oracleIntegration.updateOracle(dataType, updatedOracleAddress))
        .to.emit(oracleIntegration, "OracleUpdated")
        .withArgs(dataType, updatedOracleAddress);
    });

    it("should revert if the oracle does not exist for the data type", async function () {
      await expect(oracleIntegration.updateOracle(newDataType, updatedOracleAddress)).to.be.revertedWith("Oracle does not exist for this data type");
    });

    it("should revert if a non-owner tries to update an oracle", async function () {
      await expect(oracleIntegration.connect(addr1).updateOracle(dataType, updatedOracleAddress)).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("should revert if the new oracle address is invalid", async function () {
      await expect(oracleIntegration.updateOracle(dataType, ethers.constants.AddressZero)).to.be.revertedWith("Invalid oracle address");
    });
  });

  describe("Get Latest Data", function () {
    it("should revert if the oracle is not set for the data type", async function () {
      await expect(oracleIntegration.getLatestData(dataType)).to.be.revertedWith("Oracle not set for this data type");
    });

    // Note: Additional tests for interacting with a mock Chainlink oracle can be added here
  });

  describe("Request New Data", function () {
    beforeEach(async function () {
      await oracleIntegration.addOracle(dataType, initialOracleAddress);
    });

    it("should allow requesting new data", async function () {
      const tx = await oracleIntegration.requestNewData(dataType);
      const receipt = await tx.wait();
      const event = receipt.events.find(event => event.event === "DataRequested");
      expect(event.args.dataType).to.equal(dataType);
    });

    it("should revert if the oracle is not set for the data type", async function () {
      await expect(oracleIntegration.requestNewData(newDataType)).to.be.revertedWith("Oracle not set for this data type");
    });
  });

  describe("Get Oracle Address", function () {
    it("should return the correct oracle address", async function () {
      await oracleIntegration.addOracle(dataType, initialOracleAddress);
      expect(await oracleIntegration.getOracleAddress(dataType)).to.equal(initialOracleAddress);
    });

    it("should return address zero if the oracle is not set", async function () {
      expect(await oracleIntegration.getOracleAddress(newDataType)).to.equal(ethers.constants.AddressZero);
    });
  });
});
