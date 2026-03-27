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
 * Este contrato gestiona un airdrop por invitación.
 * El owner puede actualizar el código de invitación y los usuarios pueden reclamar
 *---------------------------------------------------------------------------*/
contract InviteCodeAirdrop {
    address public owner;
    uint256 public rewardAmount = 0.01 ether;

    string private inviteCode;
    mapping(address => bool) public claimed; // Track claims

    constructor(string memory _inviteCode) payable {
        owner = msg.sender; // Set contract deployer as owner
        inviteCode = _inviteCode; // Set initial invite code
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner"); // Check if caller is owner
        _;
    }

    function updateInviteCode(string calldata newCode) external onlyOwner {
        inviteCode = newCode; // Update invite code
    }

    function fundCampaign() external payable onlyOwner {} // Allow owner to fund the contract

    function claim(string calldata code) external {
        require(!claimed[msg.sender], "Already claimed"); // Check if user has already claimed
        require(
            keccak256(bytes(code)) == keccak256(bytes(inviteCode)), // Validate invite code
            "Invalid code"
        );

        claimed[msg.sender] = true; // Mark user as claimed
        (bool ok, ) = payable(msg.sender).call{value: rewardAmount}("");
        require(ok, "Transfer failed");
    }
}


// Diagrama de flujo que explique el funcionamiento del contrato InviteCodeAirdrop. El diagrama debe incluir los siguientes pasos:
// 1. El contrato es desplegado por el owner con un código de invitación inicial.
// 2. El owner puede actualizar el código de invitación en cualquier momento.
// 3. El owner puede financiar el contrato para asegurar que haya fondos disponibles para el airdrop.
// 4. Un usuario externo puede intentar reclamar el airdrop proporcionando un código de invitación.
// 5. El contrato verifica si el usuario ya ha reclamado el airdrop.
// 6. El contrato verifica si el código de invitación proporcionado es correcto.
// 7. Si el usuario no ha reclamado y el código es correcto, el contrato marca al usuario como reclamado y transfiere la recompensa al usuario.
// 8. Si el usuario ya ha reclamado o el código es incorrecto, el contrato rechaza la reclamación.Aquí tienes un diagrama de flujo que explica el funcionamiento del contrato InviteCodeAirdrop:       
// ```plaintext
// +-----------------------------+
// | 1. Deploy Contract          |
// | - Owner sets initial invite  |            
// |   code and funds the contract|
// +-----------------------------+
//             |
//             v
// +-----------------------------+             
// | 2. Owner Updates Invite Code|
// | - Owner can update the invite |
// |   code at any time            |
// +-----------------------------+
//             |
//             v
// +-----------------------------+             
// | 3. Owner Funds Contract      |
// | - Owner can add funds to the  |
// |   contract to ensure rewards  |
// +-----------------------------+
//             |
//             v
// +-----------------------------+            
// | 4. User Claims Airdrop       |    
// | - User provides invite code   |
// +-----------------------------+
//             |
//             v
// +-----------------------------+            
// | 5. Check if User Already     |
// |    Claimed                   |
// | - If claimed, reject claim    |
// +-----------------------------+
//             |
//             v
// +-----------------------------+            
// | 6. Validate Invite Code       |
// | - If code is incorrect, reject|
// +-----------------------------+
//             |
//             v
// +-----------------------------+           
// | 7. Process Claim              |           
// | - Mark user as claimed        |
// | - Transfer reward to user     |
// +-----------------------------+
//             |
//             v
// +-----------------------------+           
// | 8. Claim Rejected             |       
// | - If user already claimed or  |
// |   code is incorrect            |
// +-----------------------------+
// ``` 

// Donde puede haber una vulnerabilidad es en el paso 7, donde el contrato transfiere la recompensa al usuario. 
// Si el contrato no tiene suficientes fondos para cubrir la recompensa, la transferencia fallará y el usuario no recibirá la recompensa, 
// aunque haya cumplido con los requisitos para reclamarla. 
// Esto podría ser explotado por un atacante que intencionalmente agote los fondos del contrato, 
// impidiendo que otros usuarios legítimos reclamen sus recompensas.
