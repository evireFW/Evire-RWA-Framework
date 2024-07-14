const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DataVerification", function () {
  let dataVerification;

  beforeEach(async function () {
    const DataVerificationFactory = await ethers.getContractFactory("DataVerificationMock");
    dataVerification = await DataVerificationFactory.deploy();
    await dataVerification.deployed();
  });

  describe("verifyNumericValue", function () {
    it("should return true for a valid numeric value", async function () {
      const params = {
        minValue: ethers.utils.parseEther("1"),
        maxValue: ethers.utils.parseEther("100"),
        decimalPlaces: 2,
        allowNegative: false,
        authorizedSources: []
      };

      const value = ethers.utils.parseEther("50");
      expect(await dataVerification.verifyNumericValue(value, params)).to.be.true;
    });

    it("should return false for an invalid numeric value", async function () {
      const params = {
        minValue: ethers.utils.parseEther("1"),
        maxValue: ethers.utils.parseEther("100"),
        decimalPlaces: 2,
        allowNegative: false,
        authorizedSources: []
      };

      const value = ethers.utils.parseEther("200");
      expect(await dataVerification.verifyNumericValue(value, params)).to.be.false;
    });

    it("should return false for a negative value when not allowed", async function () {
      const params = {
        minValue: ethers.utils.parseEther("1"),
        maxValue: ethers.utils.parseEther("100"),
        decimalPlaces: 2,
        allowNegative: false,
        authorizedSources: []
      };

      const value = ethers.utils.parseEther("-10");
      expect(await dataVerification.verifyNumericValue(value, params)).to.be.false;
    });
  });

  describe("verifyStringPattern", function () {
    it("should return true for a matching string pattern", async function () {
      const value = "TestString";
      const pattern = ".*"; // Placeholder for actual pattern
      expect(await dataVerification.verifyStringPattern(value, pattern)).to.be.true;
    });

    it("should return false for a non-matching string pattern", async function () {
      const value = "";
      const pattern = ".*"; // Placeholder for actual pattern
      expect(await dataVerification.verifyStringPattern(value, pattern)).to.be.false;
    });
  });

  describe("verifyDataIntegrity", function () {
    it("should return true for a valid hash", async function () {
      const data = ethers.utils.toUtf8Bytes("TestData");
      const hash = ethers.utils.keccak256(data);
      expect(await dataVerification.verifyDataIntegrity(data, hash)).to.be.true;
    });

    it("should return false for an invalid hash", async function () {
      const data = ethers.utils.toUtf8Bytes("TestData");
      const hash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("OtherData"));
      expect(await dataVerification.verifyDataIntegrity(data, hash)).to.be.false;
    });
  });

  describe("verifyTimestamp", function () {
    it("should return true for a valid timestamp", async function () {
      const timestamp = Math.floor(Date.now() / 1000) - 100; // 100 seconds ago
      const maxAge = 200; // 200 seconds max age
      expect(await dataVerification.verifyTimestamp(timestamp, maxAge)).to.be.true;
    });

    it("should return false for an invalid timestamp", async function () {
      const timestamp = Math.floor(Date.now() / 1000) - 300; // 300 seconds ago
      const maxAge = 200; // 200 seconds max age
      expect(await dataVerification.verifyTimestamp(timestamp, maxAge)).to.be.false;
    });
  });

  describe("verifyDataSource", function () {
    it("should return true for an authorized data source", async function () {
      const source = owner.address;
      const params = {
        minValue: 0,
        maxValue: 0,
        decimalPlaces: 0,
        allowNegative: false,
        authorizedSources: [source]
      };

      expect(await dataVerification.verifyDataSource(source, params)).to.be.true;
    });

    it("should return false for an unauthorized data source", async function () {
      const source = owner.address;
      const params = {
        minValue: 0,
        maxValue: 0,
        decimalPlaces: 0,
        allowNegative: false,
        authorizedSources: []
      };

      expect(await dataVerification.verifyDataSource(source, params)).to.be.false;
    });
  });

  describe("verifyGeographicCoordinates", function () {
    it("should return true for valid coordinates", async function () {
      const latitude = 40;
      const longitude = -74;
      expect(await dataVerification.verifyGeographicCoordinates(latitude, longitude)).to.be.true;
    });

    it("should return false for invalid latitude", async function () {
      const latitude = 100;
      const longitude = -74;
      expect(await dataVerification.verifyGeographicCoordinates(latitude, longitude)).to.be.false;
    });

    it("should return false for invalid longitude", async function () {
      const latitude = 40;
      const longitude = -200;
      expect(await dataVerification.verifyGeographicCoordinates(latitude, longitude)).to.be.false;
    });
  });

  describe("verifyUUID", function () {
    it("should return true for a valid UUID", async function () {
      const uuid = "550e8400-e29b-41d4-a716-446655440000";
      expect(await dataVerification.verifyUUID(uuid)).to.be.true;
    });

    it("should return false for an invalid UUID", async function () {
      const uuid = "550e8400-e29b-41d4-a716-446655440000-INVALID";
      expect(await dataVerification.verifyUUID(uuid)).to.be.false;
    });
  });

  describe("verifyISO8601Date", function () {
    it("should return true for a valid ISO8601 date", async function () {
      const dateString = "2023-07-15";
      expect(await dataVerification.verifyISO8601Date(dateString)).to.be.true;
    });

    it("should return false for an invalid ISO8601 date", async function () {
      const dateString = "2023-07-150";
      expect(await dataVerification.verifyISO8601Date(dateString)).to.be.false;
    });
  });

  describe("verifySignature", function () {
    it("should return true for a valid signature", async function () {
      const message = ethers.utils.toUtf8Bytes("TestMessage");
      const messageHash = ethers.utils.keccak256(message);
      const signature = await owner.signMessage(ethers.utils.arrayify(messageHash));
      expect(await dataVerification.verifySignature(messageHash, signature, owner.address)).to.be.true;
    });

    it("should return false for an invalid signature", async function () {
      const message = ethers.utils.toUtf8Bytes("TestMessage");
      const messageHash = ethers.utils.keccak256(message);
      const signature = await addr1.signMessage(ethers.utils.arrayify(messageHash));
      expect(await dataVerification.verifySignature(messageHash, signature, owner.address)).to.be.false;
    });
  });

  describe("batchVerifyNumericValues", function () {
    it("should return true for all valid numeric values", async function () {
      const values = [ethers.utils.parseEther("10"), ethers.utils.parseEther("20")];
      const params = [
        { minValue: ethers.utils.parseEther("1"), maxValue: ethers.utils.parseEther("100"), decimalPlaces: 2, allowNegative: false, authorizedSources: [] },
        { minValue: ethers.utils.parseEther("1"), maxValue: ethers.utils.parseEther("100"), decimalPlaces: 2, allowNegative: false, authorizedSources: [] }
      ];

      expect(await dataVerification.batchVerifyNumericValues(values, params)).to.be.true;
    });

    it("should return false for some invalid numeric values", async function () {
      const values = [ethers.utils.parseEther("10"), ethers.utils.parseEther("200")];
      const params = [
        { minValue: ethers.utils.parseEther("1"), maxValue: ethers.utils.parseEther("100"), decimalPlaces: 2, allowNegative: false, authorizedSources: [] },
        { minValue: ethers.utils.parseEther("1"), maxValue: ethers.utils.parseEther("100"), decimalPlaces: 2, allowNegative: false, authorizedSources: [] }
      ];

      expect(await dataVerification.batchVerifyNumericValues(values, params)).to.be.false;
    });
  });
});
