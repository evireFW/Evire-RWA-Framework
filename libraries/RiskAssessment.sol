// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./DataVerification.sol";
import "./AssetValuation.sol";

/**
 * @title RiskAssessment
 * @dev Library for assessing risks associated with Real World Assets (RWA) on blockchain
 */
library RiskAssessment {
    using SafeMath for uint256;

    // Risk categories
    enum RiskCategory { 
        MARKET,
        CREDIT,
        LIQUIDITY,
        OPERATIONAL,
        LEGAL,
        ENVIRONMENTAL
    }

    // Risk levels
    enum RiskLevel { 
        LOW,
        MEDIUM,
        HIGH,
        CRITICAL
    }

    // Struct to hold risk assessment results
    struct RiskAssessmentResult {
        RiskCategory category;
        RiskLevel level;
        uint256 score;
        string description;
    }

    // Struct to hold risk parameters
    struct RiskParameters {
        uint256 volatility;
        uint256 correlationFactor;
        uint256 defaultProbability;
        uint256 recoveryRate;
        uint256 liquidityRatio;
        uint256 operationalErrorRate;
        uint256 legalComplianceScore;
        uint256 environmentalImpactScore;
    }

    // Events
    event RiskAssessed(address indexed asset, RiskCategory category, RiskLevel level, uint256 score);

    // Constants
    uint256 private constant RISK_THRESHOLD_LOW = 30;
    uint256 private constant RISK_THRESHOLD_MEDIUM = 60;
    uint256 private constant RISK_THRESHOLD_HIGH = 90;
    uint256 private constant PRECISION = 1e18;

    /**
     * @dev Assess overall risk for an asset
     * @param assetAddress Address of the asset contract
     * @param params Risk parameters for the asset
     * @return Array of RiskAssessmentResult structs
     */
    function assessOverallRisk(address assetAddress, RiskParameters memory params) 
        public 
        returns (RiskAssessmentResult[] memory) 
    {
        RiskAssessmentResult[] memory results = new RiskAssessmentResult[](6);

        results[0] = assessMarketRisk(assetAddress, params.volatility, params.correlationFactor);
        results[1] = assessCreditRisk(assetAddress, params.defaultProbability, params.recoveryRate);
        results[2] = assessLiquidityRisk(assetAddress, params.liquidityRatio);
        results[3] = assessOperationalRisk(assetAddress, params.operationalErrorRate);
        results[4] = assessLegalRisk(assetAddress, params.legalComplianceScore);
        results[5] = assessEnvironmentalRisk(assetAddress, params.environmentalImpactScore);

        return results;
    }

    /**
     * @dev Assess market risk for an asset
     * @param assetAddress Address of the asset contract
     * @param volatility Asset price volatility
     * @param correlationFactor Correlation with market benchmark
     * @return RiskAssessmentResult struct for market risk
     */
    function assessMarketRisk(address assetAddress, uint256 volatility, uint256 correlationFactor) 
        public 
        returns (RiskAssessmentResult memory) 
    {
        uint256 marketRiskScore = calculateMarketRiskScore(volatility, correlationFactor);
        RiskLevel riskLevel = determineRiskLevel(marketRiskScore);

        RiskAssessmentResult memory result = RiskAssessmentResult({
            category: RiskCategory.MARKET,
            level: riskLevel,
            score: marketRiskScore,
            description: "Market risk based on volatility and correlation"
        });

        emit RiskAssessed(assetAddress, RiskCategory.MARKET, riskLevel, marketRiskScore);
        return result;
    }

    /**
     * @dev Assess credit risk for an asset
     * @param assetAddress Address of the asset contract
     * @param defaultProbability Probability of default
     * @param recoveryRate Expected recovery rate in case of default
     * @return RiskAssessmentResult struct for credit risk
     */
    function assessCreditRisk(address assetAddress, uint256 defaultProbability, uint256 recoveryRate) 
        public 
        returns (RiskAssessmentResult memory) 
    {
        uint256 creditRiskScore = calculateCreditRiskScore(defaultProbability, recoveryRate);
        RiskLevel riskLevel = determineRiskLevel(creditRiskScore);

        RiskAssessmentResult memory result = RiskAssessmentResult({
            category: RiskCategory.CREDIT,
            level: riskLevel,
            score: creditRiskScore,
            description: "Credit risk based on default probability and recovery rate"
        });

        emit RiskAssessed(assetAddress, RiskCategory.CREDIT, riskLevel, creditRiskScore);
        return result;
    }

    /**
     * @dev Assess liquidity risk for an asset
     * @param assetAddress Address of the asset contract
     * @param liquidityRatio Liquidity ratio of the asset
     * @return RiskAssessmentResult struct for liquidity risk
     */
    function assessLiquidityRisk(address assetAddress, uint256 liquidityRatio) 
        public 
        returns (RiskAssessmentResult memory) 
    {
        uint256 liquidityRiskScore = calculateLiquidityRiskScore(liquidityRatio);
        RiskLevel riskLevel = determineRiskLevel(liquidityRiskScore);

        RiskAssessmentResult memory result = RiskAssessmentResult({
            category: RiskCategory.LIQUIDITY,
            level: riskLevel,
            score: liquidityRiskScore,
            description: "Liquidity risk based on liquidity ratio"
        });

        emit RiskAssessed(assetAddress, RiskCategory.LIQUIDITY, riskLevel, liquidityRiskScore);
        return result;
    }

    /**
     * @dev Assess operational risk for an asset
     * @param assetAddress Address of the asset contract
     * @param operationalErrorRate Rate of operational errors
     * @return RiskAssessmentResult struct for operational risk
     */
    function assessOperationalRisk(address assetAddress, uint256 operationalErrorRate) 
        public 
        returns (RiskAssessmentResult memory) 
    {
        uint256 operationalRiskScore = calculateOperationalRiskScore(operationalErrorRate);
        RiskLevel riskLevel = determineRiskLevel(operationalRiskScore);

        RiskAssessmentResult memory result = RiskAssessmentResult({
            category: RiskCategory.OPERATIONAL,
            level: riskLevel,
            score: operationalRiskScore,
            description: "Operational risk based on error rate"
        });

        emit RiskAssessed(assetAddress, RiskCategory.OPERATIONAL, riskLevel, operationalRiskScore);
        return result;
    }

    /**
     * @dev Assess legal risk for an asset
     * @param assetAddress Address of the asset contract
     * @param legalComplianceScore Legal compliance score
     * @return RiskAssessmentResult struct for legal risk
     */
    function assessLegalRisk(address assetAddress, uint256 legalComplianceScore) 
        public 
        returns (RiskAssessmentResult memory) 
    {
        uint256 legalRiskScore = calculateLegalRiskScore(legalComplianceScore);
        RiskLevel riskLevel = determineRiskLevel(legalRiskScore);

        RiskAssessmentResult memory result = RiskAssessmentResult({
            category: RiskCategory.LEGAL,
            level: riskLevel,
            score: legalRiskScore,
            description: "Legal risk based on compliance score"
        });

        emit RiskAssessed(assetAddress, RiskCategory.LEGAL, riskLevel, legalRiskScore);
        return result;
    }

    /**
     * @dev Assess environmental risk for an asset
     * @param assetAddress Address of the asset contract
     * @param environmentalImpactScore Environmental impact score
     * @return RiskAssessmentResult struct for environmental risk
     */
    function assessEnvironmentalRisk(address assetAddress, uint256 environmentalImpactScore) 
        public 
        returns (RiskAssessmentResult memory) 
    {
        uint256 environmentalRiskScore = calculateEnvironmentalRiskScore(environmentalImpactScore);
        RiskLevel riskLevel = determineRiskLevel(environmentalRiskScore);

        RiskAssessmentResult memory result = RiskAssessmentResult({
            category: RiskCategory.ENVIRONMENTAL,
            level: riskLevel,
            score: environmentalRiskScore,
            description: "Environmental risk based on impact score"
        });

        emit RiskAssessed(assetAddress, RiskCategory.ENVIRONMENTAL, riskLevel, environmentalRiskScore);
        return result;
    }

    /**
     * @dev Calculate market risk score
     * @param volatility Asset price volatility
     * @param correlationFactor Correlation with market benchmark
     * @return Market risk score
     */
    function calculateMarketRiskScore(uint256 volatility, uint256 correlationFactor) 
        private 
        pure 
        returns (uint256) 
    {
        return volatility.mul(correlationFactor).div(PRECISION);
    }

    /**
     * @dev Calculate credit risk score
     * @param defaultProbability Probability of default
     * @param recoveryRate Expected recovery rate in case of default
     * @return Credit risk score
     */
    function calculateCreditRiskScore(uint256 defaultProbability, uint256 recoveryRate) 
        private 
        pure 
        returns (uint256) 
    {
        return defaultProbability.mul(PRECISION.sub(recoveryRate)).div(PRECISION);
    }

    /**
     * @dev Calculate liquidity risk score
     * @param liquidityRatio Liquidity ratio of the asset
     * @return Liquidity risk score
     */
    function calculateLiquidityRiskScore(uint256 liquidityRatio) 
        private 
        pure 
        returns (uint256) 
    {
        return PRECISION.sub(liquidityRatio);
    }

    /**
     * @dev Calculate operational risk score
     * @param operationalErrorRate Rate of operational errors
     * @return Operational risk score
     */
    function calculateOperationalRiskScore(uint256 operationalErrorRate) 
        private 
        pure 
        returns (uint256) 
    {
        return operationalErrorRate.mul(2);  // Amplify the impact of operational errors
    }

    /**
     * @dev Calculate legal risk score
     * @param legalComplianceScore Legal compliance score
     * @return Legal risk score
     */
    function calculateLegalRiskScore(uint256 legalComplianceScore) 
        private 
        pure 
        returns (uint256) 
    {
        return PRECISION.sub(legalComplianceScore);
    }

    /**
     * @dev Calculate environmental risk score
     * @param environmentalImpactScore Environmental impact score
     * @return Environmental risk score
     */
    function calculateEnvironmentalRiskScore(uint256 environmentalImpactScore) 
        private 
        pure 
        returns (uint256) 
    {
        return environmentalImpactScore.mul(3).div(2);  // Amplify the impact of environmental factors
    }

    /**
     * @dev Determine risk level based on risk score
     * @param riskScore Calculated risk score
     * @return RiskLevel enum value
     */
    function determineRiskLevel(uint256 riskScore) 
        private 
        pure 
        returns (RiskLevel) 
    {
        if (riskScore < RISK_THRESHOLD_LOW) {
            return RiskLevel.LOW;
        } else if (riskScore < RISK_THRESHOLD_MEDIUM) {
            return RiskLevel.MEDIUM;
        } else if (riskScore < RISK_THRESHOLD_HIGH) {
            return RiskLevel.HIGH;
        } else {
            return RiskLevel.CRITICAL;
        }
    }
}