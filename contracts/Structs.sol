// SPDX-License-Identifier: MIT
pragma solidity 0.8.18; // solidity version

contract SimpleStorage  {

uint256 myFavoriteNumber;

// uint256[] listOfFavoriteNumbers; 
// [77, 78, 90]

// uint256 myFavoriteNumber; // 0

struct Person {
    uint256 favoriteNumber;
    string name;
}

// uint256 public favoriteNumber; 

Person public pat = Person({favoriteNumber: 7, name: "Pat"});

function store(uint256 _favoriteNumber) public {
    myFavoriteNumber = _favoriteNumber;
    // retrieve();
}

function retrieve() public view returns(uint256) {
    return myFavoriteNumber;
}

}