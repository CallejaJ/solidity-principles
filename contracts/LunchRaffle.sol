// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

 /*----------------------------------------------------------------------------
 * DISCLAIMER EDUCATIVO
 * Contrato intencionadamente vulnerable.
 * Módulo 3 - Auditoría de Smart Contracts
 * Curso de Blockchain de la Universidad de Málaga
 *---------------------------------------------------------------------------*/
 
 /*----------------------------------------------------------------------------
 * DESCRIPCIÓN
 * Este contrato organiza un sorteo sencillo entre quienes pagan una entrada. 
 *---------------------------------------------------------------------------*/
contract LunchRaffle {
    address public owner;
    uint256 public ticketPrice;
    bool public roundOpen = true;

    address[] public players;

    constructor(uint256 _ticketPrice) {
        owner = msg.sender;
        ticketPrice = _ticketPrice;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function join() external payable {
        require(roundOpen, "Round closed");
        require(msg.value == ticketPrice, "Wrong ticket price");
        players.push(msg.sender);
    }

    function playerCount() external view returns (uint256) {
        return players.length;
    }

    function closeRound() external onlyOwner {
        require(players.length > 0, "No players");
        roundOpen = false;
    }

    function pickWinner() external onlyOwner {
        require(!roundOpen, "Round still open");

        uint256 index = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, block.prevrandao, players.length) // Not truly random, but serves for demonstration purposes
            )
        ) % players.length;

        address winner = players[index];

        delete players;
        roundOpen = true; // Reopen for next round

        (bool ok, ) = payable(winner).call{value: address(this).balance}(""); // Transfer prize to winner
        require(ok, "Prize transfer failed");  // 
    }
}



// Diagrama de flujo del contrato LunchRaffle:
// ```plaintext
// +-----------------------------+
// | 1. Deploy Contract          |
// | - Owner sets ticket price    |
// +-----------------------------+
//             |
//             v
// +-----------------------------+
// | 2. Users Join Raffle        |
// | - Users pay ticket price     |
// | - Users are added to players |
// +-----------------------------+
//             |
//             v
// +-----------------------------+
// | 3. Close Round              |
// | - Owner closes the round     |
// | - No more entries allowed    |
// +-----------------------------+
//             |
//             v
// +-----------------------------+
// | 4. Pick Winner              |
// | - Owner picks a winner       |
// | - Randomly selects from      |
// |   players array              |
// +-----------------------------+
//             |
//             v
// +-----------------------------+
// | 5. Transfer Prize           |
// | - Transfer contract balance  |
// |   to winner                  |
// | - Reset players array        |
// | - Reopen round               |
// +-----------------------------+
// ```

// Pseudoaleatoriedad débil en la función pickWinner, que puede ser explotada por un atacante para predecir o manipular el resultado del sorteo. 
// Además, no hay restricciones sobre quién puede llamar a esta función, lo que podría permitir a un atacante cerrar la ronda y elegir un ganador de manera maliciosa.