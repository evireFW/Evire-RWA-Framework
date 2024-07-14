const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ComplianceChecks Library", function () {
    let ComplianceChecks;
    let complianceChecks;

    before(async function () {
        // Deploy the ComplianceChecks library
        const ComplianceChecksFactory = await ethers.getContractFactory("ComplianceChecks");
        complianceChecks = await ComplianceChecksFactory.deploy();
        await complianceChecks.deployed();

        // Link the library to a test contract that uses it
        const TestComplianceContractFactory = await ethers.getContractFactory("TestComplianceContract", {
            libraries: {
                ComplianceChecks: complianceChecks.address
            }
        });
        this.testComplianceContract = await TestComplianceContractFactory.deploy();
        await this.testComplianceContract.deployed();
    });

    describe("KYC Compliance", function () {
        it("should return true for an address that passed KYC", async function () {
            const address = "0x1234567890123456789012345678901234567890";
            await this.testComplianceContract.setKYCStatus(address, true);
            const result = await this.testComplianceContract.checkKYCCompliance(address);
            expect(result).to.be.true;
        });

        it("should return false for an address that did not pass KYC", async function () {
            const address = "0x0987654321098765432109876543210987654321";
            await this.testComplianceContract.setKYCStatus(address, false);
            const result = await this.testComplianceContract.checkKYCCompliance(address);
            expect(result).to.be.false;
        });
    });

    describe("AML Compliance", function () {
        it("should return true for an address that passed AML", async function () {
            const address = "0x1234567890123456789012345678901234567890";
            await this.testComplianceContract.setAMLStatus(address, true);
            const result = await this.testComplianceContract.checkAMLCompliance(address);
            expect(result).to.be.true;
        });

        it("should return false for an address that did not pass AML", async function () {
            const address = "0x0987654321098765432109876543210987654321";
            await this.testComplianceContract.setAMLStatus(address, false);
            const result = await this.testComplianceContract.checkAMLCompliance(address);
            expect(result).to.be.false;
        });
    });

    describe("Combined KYC and AML Compliance", function () {
        it("should return true for an address that passed both KYC and AML", async function () {
            const address = "0x1234567890123456789012345678901234567890";
            await this.testComplianceContract.setKYCStatus(address, true);
            await this.testComplianceContract.setAMLStatus(address, true);
            const result = await this.testComplianceContract.checkFullCompliance(address);
            expect(result).to.be.true;
        });

        it("should return false for an address that failed either KYC or AML", async function () {
            const address = "0x0987654321098765432109876543210987654321";
            await this.testComplianceContract.setKYCStatus(address, false);
            await this.testComplianceContract.setAMLStatus(address, true);
            const result = await this.testComplianceContract.checkFullCompliance(address);
            expect(result).to.be.false;

            await this.testComplianceContract.setKYCStatus(address, true);
            await this.testComplianceContract.setAMLStatus(address, false);
            const result2 = await this.testComplianceContract.checkFullCompliance(address);
            expect(result2).to.be.false;
        });
    });
});
