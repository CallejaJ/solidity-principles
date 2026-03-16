// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract SimpleStorage {
    uint storedData;

    function set(uint x) public {
        storedData = multiply(storedData , x);
    }

     function multiply(uint c, uint d) pure public  returns (uint) {
        return c * d ;
    }
}