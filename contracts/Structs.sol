// SPDX-License-Identifier: MIT
pragma solidity 0.8.18; // solidity version

contract SimpleStorage  {

// favoriteNumber gets initialized to 0 if no value

// uint256 myFavoriteNumber; // 0

// struct Person {
//     uint256 favoriteNumber;
//     string name;
// }

uint256 public favoriteNumber; 


function store(uint256 _favoriteNumber) public {
    favoriteNumber = _favoriteNumber;
    // retrieve();
}

function retrieve() public view returns(uint256) {
    return favoriteNumber;
}

}