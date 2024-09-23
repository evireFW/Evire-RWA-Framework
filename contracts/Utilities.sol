// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title Utilities
 * @dev A library of utility functions for the Evire-RWA-Framework
 */
library Utilities {
    /**
     * @dev Calculates the percentage of a value
     * @param value The total value
     * @param percentage The percentage to calculate
     * @return The calculated percentage of the value
     */
    function calculatePercentage(uint256 value, uint256 percentage) internal pure returns (uint256) {
        return (value * percentage) / 100;
    }

    /**
     * @dev Converts a uint256 to a string
     * @param value The uint256 value to convert
     * @return The string representation of the value
     */
    function uintToString(uint256 value) internal pure returns (string memory) {
        return Strings.toString(value);
    }

    /**
     * @dev Checks if two strings are equal
     * @param a The first string
     * @param b The second string
     * @return True if the strings are equal, false otherwise
     */
    function stringEqual(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    /**
     * @dev Calculates the average of an array of uint256 values
     * @param values The array of values
     * @return The average of the values
     */
    function calculateAverage(uint256[] memory values) internal pure returns (uint256) {
        require(values.length > 0, "Array must not be empty");
        uint256 sum = 0;
        for (uint256 i = 0; i < values.length; i++) {
            sum += values[i];
        }
        return sum / values.length;
    }

    /**
     * @dev Finds the maximum value in an array of uint256 values
     * @param values The array of values
     * @return The maximum value in the array
     */
    function findMaxValue(uint256[] memory values) internal pure returns (uint256) {
        require(values.length > 0, "Array must not be empty");
        uint256 maxValue = values[0];
        for (uint256 i = 1; i < values.length; i++) {
            if (values[i] > maxValue) {
                maxValue = values[i];
            }
        }
        return maxValue;
    }

    /**
     * @dev Checks if an address is a contract
     * @param addr The address to check
     * @return True if the address is a contract, false if it's an externally owned account
     */
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    /**
     * @dev Converts a bytes32 to a string
     * @param data The bytes32 data to convert
     * @return The string representation of the bytes32 data
     */
    function bytes32ToString(bytes32 data) internal pure returns (string memory) {
        uint8 i = 0;
        while (i < 32 && data[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (uint8 j = 0; j < i; j++) {
            bytesArray[j] = data[j];
        }
        return string(bytesArray);
    }

    /**
     * @dev Finds the minimum value in an array of uint256 values
     * @param values The array of values
     * @return The minimum value in the array
     */
    function findMinValue(uint256[] memory values) internal pure returns (uint256) {
        require(values.length > 0, "Array must not be empty");
        uint256 minValue = values[0];
        for (uint256 i = 1; i < values.length; i++) {
            if (values[i] < minValue) {
                minValue = values[i];
            }
        }
        return minValue;
    }

    /**
     * @dev Checks if a string is empty
     * @param str The string to check
     * @return True if the string is empty, false otherwise
     */
    function isStringEmpty(string memory str) internal pure returns (bool) {
        return bytes(str).length == 0;
    }

    /**
     * @dev Converts an address to a string
     * @param addr The address to convert
     * @return The string representation of the address
     */
    function addressToString(address addr) internal pure returns (string memory) {
        return Strings.toHexString(uint256(uint160(addr)), 20);
    }

    /**
     * @dev Converts a string to lowercase
     * @param str The string to convert
     * @return The lowercase version of the string
     */
    function toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            if ((bStr[i] >= 0x41) && (bStr[i] <= 0x5A)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
}
