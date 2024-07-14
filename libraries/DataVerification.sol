// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title DataVerification
 * @dev Library for verifying and validating various types of data related to Real World Assets (RWA)
 */
library DataVerification {
    using SafeMath for uint256;
    using Strings for uint256;

    // Custom errors
    error InvalidDataFormat();
    error DataOutOfRange();
    error InconsistentData();
    error UnauthorizedSource();

    // Struct to hold verification parameters
    struct VerificationParams {
        uint256 minValue;
        uint256 maxValue;
        uint8 decimalPlaces;
        bool allowNegative;
        address[] authorizedSources;
    }

    /**
     * @dev Verifies a numeric value against specified parameters
     * @param value The value to verify
     * @param params The verification parameters
     * @return bool True if the value is valid, false otherwise
     */
    function verifyNumericValue(int256 value, VerificationParams memory params) public pure returns (bool) {
        if (!params.allowNegative && value < 0) {
            return false;
        }

        uint256 absValue = value < 0 ? uint256(-value) : uint256(value);

        if (absValue < params.minValue || absValue > params.maxValue) {
            return false;
        }

        return true;
    }

    /**
     * @dev Verifies a string value against a regular expression pattern
     * @param value The string to verify
     * @param pattern The regular expression pattern
     * @return bool True if the value matches the pattern, false otherwise
     */
    function verifyStringPattern(string memory value, string memory pattern) public pure returns (bool) {
        // Note: Solidity doesn't support regex directly. This is a placeholder for off-chain verification.
        // In a real implementation, this would be done off-chain or using a specialized oracle.
        return bytes(value).length > 0 && bytes(pattern).length > 0;
    }

    /**
     * @dev Verifies the integrity of a hash
     * @param data The original data
     * @param hash The hash to verify
     * @return bool True if the hash is valid, false otherwise
     */
    function verifyDataIntegrity(bytes memory data, bytes32 hash) public pure returns (bool) {
        return keccak256(data) == hash;
    }

    /**
     * @dev Verifies that a timestamp is within an acceptable range
     * @param timestamp The timestamp to verify
     * @param maxAge The maximum age of the timestamp in seconds
     * @return bool True if the timestamp is valid, false otherwise
     */
    function verifyTimestamp(uint256 timestamp, uint256 maxAge) public view returns (bool) {
        return timestamp <= block.timestamp && block.timestamp.sub(timestamp) <= maxAge;
    }

    /**
     * @dev Verifies that a data source is authorized
     * @param source The address of the data source
     * @param params The verification parameters containing authorized sources
     * @return bool True if the source is authorized, false otherwise
     */
    function verifyDataSource(address source, VerificationParams memory params) public pure returns (bool) {
        for (uint256 i = 0; i < params.authorizedSources.length; i++) {
            if (params.authorizedSources[i] == source) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Verifies a set of geographic coordinates
     * @param latitude The latitude value (-90 to 90)
     * @param longitude The longitude value (-180 to 180)
     * @return bool True if the coordinates are valid, false otherwise
     */
    function verifyGeographicCoordinates(int256 latitude, int256 longitude) public pure returns (bool) {
        return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;
    }

    /**
     * @dev Verifies a UUID (Universally Unique Identifier)
     * @param uuid The UUID to verify
     * @return bool True if the UUID is valid, false otherwise
     */
    function verifyUUID(bytes16 uuid) public pure returns (bool) {
        // Check if the UUID is not zero
        if (uuid == 0) {
            return false;
        }

        // Verify version (should be 4 for random UUID)
        bytes1 version = uuid[6];
        if ((version & 0xf0) != 0x40) {
            return false;
        }

        // Verify variant (should be 1)
        bytes1 variant = uuid[8];
        if ((variant & 0xc0) != 0x80) {
            return false;
        }

        return true;
    }

    /**
     * @dev Verifies the format of an ISO8601 date string
     * @param dateString The date string to verify
     * @return bool True if the date string is valid, false otherwise
     */
    function verifyISO8601Date(string memory dateString) public pure returns (bool) {
        bytes memory dateBytes = bytes(dateString);
        
        // Basic length check
        if (dateBytes.length != 10) {
            return false;
        }

        // Check format (YYYY-MM-DD)
        for (uint i = 0; i < 10; i++) {
            if (i == 4 || i == 7) {
                if (dateBytes[i] != '-') {
                    return false;
                }
            } else {
                if (dateBytes[i] < '0' || dateBytes[i] > '9') {
                    return false;
                }
            }
        }

        // Additional checks could be implemented for valid month/day ranges
        return true;
    }

    /**
     * @dev Verifies a digital signature
     * @param message The original message
     * @param signature The signature to verify
     * @param signer The address of the supposed signer
     * @return bool True if the signature is valid, false otherwise
     */
    function verifySignature(bytes32 message, bytes memory signature, address signer) public pure returns (bool) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signature.length != 65) {
            return false;
        }

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return false;
        }

        address recoveredAddress = ecrecover(message, v, r, s);
        return recoveredAddress == signer;
    }

    /**
     * @dev Batch verification of multiple data points
     * @param values Array of values to verify
     * @param params Array of corresponding verification parameters
     * @return bool True if all values are valid, false otherwise
     */
    function batchVerifyNumericValues(int256[] memory values, VerificationParams[] memory params) public pure returns (bool) {
        require(values.length == params.length, "Mismatched array lengths");

        for (uint256 i = 0; i < values.length; i++) {
            if (!verifyNumericValue(values[i], params[i])) {
                return false;
            }
        }

        return true;
    }
}