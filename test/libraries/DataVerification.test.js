const DataVerification = artifacts.require("DataVerification");
const { expect } = require("chai");

contract("DataVerification", accounts => {
  let dataVerificationInstance;

  before(async () => {
    dataVerificationInstance = await DataVerification.deployed();
  });

  describe("verifyData", () => {
    it("should return true for correct data verification", async () => {
      const sampleData = web3.utils.keccak256("Sample Data");
      const isValid = await dataVerificationInstance.verifyData(sampleData, sampleData);
      expect(isValid).to.be.true;
    });

    it("should return false for incorrect data verification", async () => {
      const sampleData = web3.utils.keccak256("Sample Data");
      const incorrectData = web3.utils.keccak256("Incorrect Data");
      const isValid = await dataVerificationInstance.verifyData(sampleData, incorrectData);
      expect(isValid).to.be.false;
    });
  });

  describe("getHash", () => {
    it("should return the correct hash of the given data", async () => {
      const data = "Some important data";
      const expectedHash = web3.utils.keccak256(data);
      const hash = await dataVerificationInstance.getHash(data);
      expect(hash).to.equal(expectedHash);
    });
  });

  describe("verifySignature", () => {
    it("should return true for valid signature", async () => {
      const message = "Message to sign";
      const hash = web3.utils.keccak256(message);
      const signature = await web3.eth.sign(hash, accounts[0]);
      const isValid = await dataVerificationInstance.verifySignature(hash, signature, accounts[0]);
      expect(isValid).to.be.true;
    });

    it("should return false for invalid signature", async () => {
      const message = "Message to sign";
      const hash = web3.utils.keccak256(message);
      const invalidSignature = "0x" + "00".repeat(65);
      const isValid = await dataVerificationInstance.verifySignature(hash, invalidSignature, accounts[0]);
      expect(isValid).to.be.false;
    });
  });

  describe("verifyMultiSignature", () => {
    it("should return true for valid multi-signature", async () => {
      const message = "Multi-signed message";
      const hash = web3.utils.keccak256(message);
      const signature1 = await web3.eth.sign(hash, accounts[0]);
      const signature2 = await web3.eth.sign(hash, accounts[1]);
      const signatures = [signature1, signature2];
      const signers = [accounts[0], accounts[1]];
      const isValid = await dataVerificationInstance.verifyMultiSignature(hash, signatures, signers);
      expect(isValid).to.be.true;
    });

    it("should return false for invalid multi-signature", async () => {
      const message = "Multi-signed message";
      const hash = web3.utils.keccak256(message);
      const signature1 = await web3.eth.sign(hash, accounts[0]);
      const invalidSignature = "0x" + "00".repeat(65);
      const signatures = [signature1, invalidSignature];
      const signers = [accounts[0], accounts[1]];
      const isValid = await dataVerificationInstance.verifyMultiSignature(hash, signatures, signers);
      expect(isValid).to.be.false;
    });
  });

});
