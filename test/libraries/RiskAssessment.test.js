const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("RiskAssessment", function () {
  let RiskAssessment;
  let owner, addr1;
  let riskParameters;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();

    const RiskAssessmentFactory = await ethers.getContractFactory("RiskAssessmentMock");
    RiskAssessment = await RiskAssessmentFactory.deploy();
    await RiskAssessment.deployed();

    riskParameters = {
      volatility: ethers.utils.parseEther("0.2"),
      correlationFactor: ethers.utils.parseEther("0.5"),
      defaultProbability: ethers.utils.parseEther("0.01"),
      recoveryRate: ethers.utils.parseEther("0.4"),
      liquidityRatio: ethers.utils.parseEther("0.7"),
      operationalErrorRate: ethers.utils.parseEther("0.05"),
      legalComplianceScore: ethers.utils.parseEther("0.9"),
      environmentalImpactScore: ethers.utils.parseEther("0.3")
    };
  });

  describe("assessOverallRisk", function () {
    it("should assess overall risk correctly", async function () {
      const results = await RiskAssessment.assessOverallRisk(addr1.address, riskParameters);

      expect(results.length).to.equal(6);

      const categories = [
        "MARKET",
        "CREDIT",
        "LIQUIDITY",
        "OPERATIONAL",
        "LEGAL",
        "ENVIRONMENTAL"
      ];

      for (let i = 0; i < results.length; i++) {
        expect(results[i].category).to.equal(categories[i]);
        expect(results[i].score).to.be.a("string");
        expect(results[i].description).to.be.a("string");
      }
    });
  });

  describe("assessMarketRisk", function () {
    it("should assess market risk correctly", async function () {
      const result = await RiskAssessment.assessMarketRisk(addr1.address, riskParameters.volatility, riskParameters.correlationFactor);
      const expectedScore = riskParameters.volatility.mul(riskParameters.correlationFactor).div(ethers.utils.parseEther("1"));

      expect(result.category).to.equal("MARKET");
      expect(result.score).to.equal(expectedScore.toString());
      expect(result.description).to.equal("Market risk based on volatility and correlation");
    });
  });

  describe("assessCreditRisk", function () {
    it("should assess credit risk correctly", async function () {
      const result = await RiskAssessment.assessCreditRisk(addr1.address, riskParameters.defaultProbability, riskParameters.recoveryRate);
      const expectedScore = riskParameters.defaultProbability.mul(ethers.utils.parseEther("1").sub(riskParameters.recoveryRate)).div(ethers.utils.parseEther("1"));

      expect(result.category).to.equal("CREDIT");
      expect(result.score).to.equal(expectedScore.toString());
      expect(result.description).to.equal("Credit risk based on default probability and recovery rate");
    });
  });

  describe("assessLiquidityRisk", function () {
    it("should assess liquidity risk correctly", async function () {
      const result = await RiskAssessment.assessLiquidityRisk(addr1.address, riskParameters.liquidityRatio);
      const expectedScore = ethers.utils.parseEther("1").sub(riskParameters.liquidityRatio);

      expect(result.category).to.equal("LIQUIDITY");
      expect(result.score).to.equal(expectedScore.toString());
      expect(result.description).to.equal("Liquidity risk based on liquidity ratio");
    });
  });

  describe("assessOperationalRisk", function () {
    it("should assess operational risk correctly", async function () {
      const result = await RiskAssessment.assessOperationalRisk(addr1.address, riskParameters.operationalErrorRate);
      const expectedScore = riskParameters.operationalErrorRate.mul(2);

      expect(result.category).to.equal("OPERATIONAL");
      expect(result.score).to.equal(expectedScore.toString());
      expect(result.description).to.equal("Operational risk based on error rate");
    });
  });

  describe("assessLegalRisk", function () {
    it("should assess legal risk correctly", async function () {
      const result = await RiskAssessment.assessLegalRisk(addr1.address, riskParameters.legalComplianceScore);
      const expectedScore = ethers.utils.parseEther("1").sub(riskParameters.legalComplianceScore);

      expect(result.category).to.equal("LEGAL");
      expect(result.score).to.equal(expectedScore.toString());
      expect(result.description).to.equal("Legal risk based on compliance score");
    });
  });

  describe("assessEnvironmentalRisk", function () {
    it("should assess environmental risk correctly", async function () {
      const result = await RiskAssessment.assessEnvironmentalRisk(addr1.address, riskParameters.environmentalImpactScore);
      const expectedScore = riskParameters.environmentalImpactScore.mul(3).div(2);

      expect(result.category).to.equal("ENVIRONMENTAL");
      expect(result.score).to.equal(expectedScore.toString());
      expect(result.description).to.equal("Environmental risk based on impact score");
    });
  });

  describe("determineRiskLevel", function () {
    it("should determine risk level correctly", async function () {
      const lowRisk = await RiskAssessment.determineRiskLevel(ethers.utils.parseEther("20"));
      expect(lowRisk).to.equal("LOW");

      const mediumRisk = await RiskAssessment.determineRiskLevel(ethers.utils.parseEther("50"));
      expect(mediumRisk).to.equal("MEDIUM");

      const highRisk = await RiskAssessment.determineRiskLevel(ethers.utils.parseEther("80"));
      expect(highRisk).to.equal("HIGH");

      const criticalRisk = await RiskAssessment.determineRiskLevel(ethers.utils.parseEther("100"));
      expect(criticalRisk).to.equal("CRITICAL");
    });
  });
});
