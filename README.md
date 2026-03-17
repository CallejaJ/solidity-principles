# Solidity Principles

<div align="left">
    <img src="https://img.shields.io/badge/Solidity-0.8+-363636?style=for-the-badge&logo=solidity" alt="Solidity" />
    <img src="https://img.shields.io/badge/Ethereum-EVM-3C3C3D?style=for-the-badge&logo=ethereum" alt="Ethereum" />
    <img src="https://img.shields.io/badge/Remix-IDE-181E29?style=for-the-badge" alt="Remix" />
    <img src="https://img.shields.io/badge/License-GPL--3.0-blue?style=for-the-badge" alt="License" />
</div>

<p align="left">
    <i>Progressive smart contract exercises exploring storage patterns, access control, and on-chain data structures in Solidity.</i>
</p>

## Storage Contracts

Each version builds on the previous one, adding a new concept while keeping the code simple.

| Contract | Concept | Key Addition |
|---|---|---|
| **Storage1** | Elementary operations | `pure` function (two args) and `view` function (one arg) for multiplication |
| **Storage2** | Gas cost observation | Same logic as Storage1, used to compare gas between `set()` and read-only calls |
| **Storage3** | Error handling | Overflow, underflow and division-by-zero checks with `require` |
| **Storage4** | Data type cost comparison | Separate `uint8`, `uint16`, `uint128`, `uint256` variables to compare gas |
| **Storage5** | Read restriction | Only the last writer can read the value; others receive `0` |
| **Storage6** | Constructor | Initial value set on deployment via `constructor(uint)` |
| **Storage7** | Owner-only writes | `onlyOwner` modifier restricts `set()` to the deployer |

## Agenda Contracts

On-chain contact book where each entry holds an ETH address and a name. Versions add progressive access control and search capabilities.

| Contract | Concept | Key Addition |
|---|---|---|
| **Agenda1** | Basic entries | Global contact list with `addContact` and `getContact` |
| **Agenda2** | Per-user storage | `mapping(address => Contact[])` gives each user their own book |
| **Agenda3** | Edit and delete | `editContact` and `deleteContact` with swap-and-pop pattern |
| **Agenda4** | Time-limited delegation | `grantAccess(delegate, seconds)` for read-only access with expiry |
| **Agenda5** | Search | `searchByAddress` and `searchByName` using `keccak256` for string comparison |

## Storage Design

The **StorageContracts** file demonstrates how Solidity handles state writes versus read-only calls. Writing to storage (`SSTORE`) costs around 20,000 gas for a cold slot, while `pure` and `view` functions cost zero gas when called externally. **Storage4** shows that the EVM always operates on 256-bit words, so smaller types like `uint8` do not reduce gas per individual slot.

## Access Control Model

The **AgendaContracts** file explores three levels of access control. Per-user isolation is achieved through `msg.sender` as the mapping key, ensuring no user can access another's data. Time-limited delegation uses `block.timestamp` to auto-expire permissions. Owner-only restriction in **Storage7** uses a `modifier` that checks `msg.sender` against the deployer address stored at construction.

## System Architecture

| Component | Role |
|---|---|
| **Remix IDE** | Development environment for compiling, deploying and testing all contracts |
| **Solidity Compiler 0.8+** | Provides built-in checked arithmetic (overflow/underflow protection) |
| **EVM (JavaScript VM)** | Local blockchain used in Remix for testing without real gas costs |
| **GitHub** | Version control and repository hosting |

## Technology Stack

- **Language**: Solidity 0.8+
- **IDE**: Remix IDE (browser-based)
- **Runtime**: EVM-compatible JavaScript VM (Remix default)
- **Version Control**: Git, GitHub

## Key Features

1. **Incremental contract versions** — each file progresses from basic to advanced, one concept at a time
2. **Pure vs view comparison** — demonstrates the gas difference between state-reading and stateless functions
3. **Built-in overflow protection** — leverages Solidity 0.8 checked arithmetic instead of SafeMath
4. **Swap-and-pop deletion** — avoids gaps in dynamic arrays when removing contacts
5. **Time-based delegation** — read-only access expires automatically using `block.timestamp`
6. **String search via hashing** — uses `keccak256` to compare strings since Solidity lacks native string equality

## Testing Strategy

All contracts are tested manually in **Remix IDE** using the JavaScript VM environment. Each contract is deployed, and functions are called with different accounts from the Remix account selector to verify access control. Gas costs are compared by reading the transaction and execution cost fields in the Remix console. Error cases (overflow, division by zero, unauthorized access) are tested by triggering reverts and confirming the expected error messages.

## Project Setup

1. Open [Remix IDE](https://remix.ethereum.org)

2. Create the contract files in the root of your workspace:

   ```
   StorageContracts.sol
   AgendaContracts.sol
   ```

3. Select compiler version `0.8.0` or higher and compile both files

4. In the Deploy tab, select **Remix VM** as the environment

5. Deploy any contract and interact with it using the generated UI

---

Built for Ethereum / EVM-compatible chains.
