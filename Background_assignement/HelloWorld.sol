// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

/**
 * @title HelloWorld
 * @dev Store an unsigned integer and then retrieve it
 */
contract HelloWorld {

    uint number; // variable used to store the value

    /**
     * @dev Store the given value in the contract
     * @param _number value to store
     */
    function store(uint _number) public {
        number = _number;
    }

    /**
     * @dev Retrives the value stored
     * @return value of number
     */
    function retrieve() public view returns (uint) {
        return number;
    }
}