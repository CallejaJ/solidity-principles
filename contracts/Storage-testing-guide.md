# Storage Contracts - Testing Guide (Remix IDE)

## General Setup

Use the **Deploy & Run Transactions** tab. Environment: **Remix VM**. Use the **ACCOUNT** dropdown to switch between users.

Important: for contracts without constructor (Storage1 to Storage5), the initial value of `storedData` is `0`. Multiplying by 0 always gives 0, so keep that in mind when testing.

---

## Storage1 - Pure and View Functions

### Deploy

Select `Storage1` and click Deploy. No parameters needed.

### Test 1: Initial value is zero

| Step | Action | Details |
|---|---|---|
| 1 | Call `get` | Should return `0` |

### Test 2: Multiply with zero always gives zero

| Step | Action | Details |
|---|---|---|
| 1 | Call `set` | Parameter: `5` |
| 2 | Call `get` | Should return `0` (because 0 * 5 = 0) |

### Test 3: Test the pure function directly

| Step | Action | Details |
|---|---|---|
| 1 | Call `multiplicar` | Parameters: `3, 4` |
| 2 | Expected result | Returns `12` |
| 3 | Check the gas | In the console it shows very low or zero gas because pure does not read or write storage |

### Test 4: Test the view function

| Step | Action | Details |
|---|---|---|
| 1 | Call `multiplicarConEstado` | Parameter: `5` |
| 2 | Expected result | Returns `0` (because storedData is still 0) |
| 3 | Check the gas | Also very low, view only reads but does not write |

---

## Storage2 - Gas Cost Comparison

### Deploy

Select `Storage2` and click Deploy. No parameters needed.

### Test 1: Compare gas costs

| Step | Action | Details |
|---|---|---|
| 1 | Call `set` | Parameter: `5` |
| 2 | Look at the console | Note the **transaction cost** and **execution cost** |
| 3 | Call `multiplicar` | Parameters: `3, 4` |
| 4 | Look at the console | The gas cost should be much lower than set |
| 5 | Call `multiplicarConEstado` | Parameter: `5` |
| 6 | Look at the console | Also much lower than set |

### What to look for

| Function | Type | Writes to storage | Gas |
|---|---|---|---|
| `set` | writes state | Yes (SSTORE) | High (~24000+) |
| `multiplicar` | pure | No | Very low |
| `multiplicarConEstado` | view | No (only reads) | Very low |

---

## Storage3 - Error Handling

### Deploy

Select `Storage3` and click Deploy. No parameters needed.

### Test 1: Overflow on addition

| Step | Action | Details |
|---|---|---|
| 1 | Call `sumar` | Parameters: `115792089237316195423570985008687907853269984665640564039457584007913129639935, 1` (max uint256 + 1) |
| 2 | Expected result | Reverts automatically (overflow protection from Solidity 0.8) |

### Test 2: Underflow on subtraction

| Step | Action | Details |
|---|---|---|
| 1 | Call `restar` | Parameters: `3, 10` |
| 2 | Expected result | Reverts automatically (3 - 10 would be negative, not allowed in uint) |

### Test 3: Division by zero

| Step | Action | Details |
|---|---|---|
| 1 | Call `dividir` | Parameters: `10, 0` |
| 2 | Expected result | Reverts with "No se puede dividir entre cero" |

### Test 4: Normal operations work fine

| Step | Action | Details |
|---|---|---|
| 1 | Call `sumar` | Parameters: `10, 20` — returns `30` |
| 2 | Call `restar` | Parameters: `20, 5` — returns `15` |
| 3 | Call `multiplicar` | Parameters: `6, 7` — returns `42` |
| 4 | Call `dividir` | Parameters: `20, 4` — returns `5` |

### Test 5: Division rounds down

| Step | Action | Details |
|---|---|---|
| 1 | Call `dividir` | Parameters: `10, 3` |
| 2 | Expected result | Returns `3` (not 3.33 — Solidity has no decimals, always rounds down) |

---

## Storage4 - Data Type Cost Comparison

### Deploy

Select `Storage4` and click Deploy. No parameters needed.

### Test 1: Compare gas for different types

| Step | Action | Details |
|---|---|---|
| 1 | Call `setUint8` | Parameter: `50` — note the gas in the console |
| 2 | Call `setUint16` | Parameter: `50` — note the gas |
| 3 | Call `setUint128` | Parameter: `50` — note the gas |
| 4 | Call `setUint256` | Parameter: `50` — note the gas |

### What to look for

| Type | Expected gas | Why |
|---|---|---|
| `uint8` | Similar or slightly higher | EVM uses 256-bit words, needs extra masking operations |
| `uint16` | Similar or slightly higher | Same reason |
| `uint128` | Similar or slightly higher | Same reason |
| `uint256` | Baseline | Native EVM word size, no extra operations needed |

The conclusion: using smaller types does not save gas for individual variables. The EVM always works with 256-bit slots.

### Test 2: Verify getters

| Step | Action | Details |
|---|---|---|
| 1 | Call `getUint8` | Should return `50` |
| 2 | Call `getUint16` | Should return `50` |
| 3 | Call `getUint128` | Should return `50` |
| 4 | Call `getUint256` | Should return `50` |

### Test 3: Type limits

| Step | Action | Details |
|---|---|---|
| 1 | Call `setUint8` | Parameter: `256` (max uint8 is 255) |
| 2 | Expected result | Reverts because 256 does not fit in uint8 |
| 3 | Call `setUint8` | Parameter: `255` — should work |

---

## Storage5 - Read Restriction

### Deploy

Select `Storage5` and click Deploy. No parameters needed.

Note: storedData starts at 0. Multiplying by 0 gives 0. Use `set` carefully.

### Test 1: Writer can read their value

| Step | Action | Details |
|---|---|---|
| 1 | Stay on account 1 | |
| 2 | Call `set` | Parameter: `7` (but 0 * 7 = 0, so storedData stays 0) |
| 3 | Call `get` | Should return `0` (you are the writer, so you see the real value) |

### Test 2: Non-writer gets zero

| Step | Action | Details |
|---|---|---|
| 1 | Switch to account 2 | |
| 2 | Call `get` | Should return `0` (but for a different reason: you are not the writer) |

### Test 3: Different user becomes the writer

| Step | Action | Details |
|---|---|---|
| 1 | Stay on account 2 | |
| 2 | Call `set` | Parameter: `5` (still 0 * 5 = 0) |
| 3 | Call `get` | Returns `0` (account 2 is now the writer) |
| 4 | Switch to account 1 | |
| 5 | Call `get` | Returns `0` (account 1 is no longer the writer) |

Note: because the initial value is 0, the multiplication always gives 0. To see the restriction in action properly, use Storage6 which has a constructor with an initial value.

---

## Storage6 - Constructor with Initial Value

### Deploy

Select `Storage6` and put this next to the Deploy button:

```
2
```

That sets the initial value to 2.

### Test 1: Initial value works

| Step | Action | Details |
|---|---|---|
| 1 | Call `get` | Should return `2` (the deployer is the initial writer) |

### Test 2: Multiply works with non-zero initial value

| Step | Action | Details |
|---|---|---|
| 1 | Call `set` | Parameter: `4` |
| 2 | Call `get` | Should return `8` (because 2 * 4 = 8) |
| 3 | Call `set` | Parameter: `3` |
| 4 | Call `get` | Should return `24` (because 8 * 3 = 24) |

### Test 3: Read restriction works

| Step | Action | Details |
|---|---|---|
| 1 | Switch to account 2 | |
| 2 | Call `get` | Should return `0` (not the writer) |
| 3 | Switch back to account 1 | |
| 4 | Call `get` | Should return `24` (the writer) |

### Test 4: New writer takes over

| Step | Action | Details |
|---|---|---|
| 1 | Switch to account 2 | |
| 2 | Call `set` | Parameter: `2` (24 * 2 = 48) |
| 3 | Call `get` | Should return `48` (account 2 is now the writer) |
| 4 | Switch to account 1 | |
| 5 | Call `get` | Should return `0` (account 1 lost writer status) |

---

## Storage7 - Only Owner Can Write

### Deploy

Select `Storage7` and put this next to the Deploy button:

```
2
```

### Test 1: Owner can set values

| Step | Action | Details |
|---|---|---|
| 1 | Call `get` | Should return `2` |
| 2 | Call `set` | Parameter: `5` |
| 3 | Call `get` | Should return `10` (2 * 5 = 10) |

### Test 2: Non-owner cannot set values

| Step | Action | Details |
|---|---|---|
| 1 | Switch to account 2 | |
| 2 | Call `set` | Parameter: `3` |
| 3 | Expected result | Reverts with "Solo el propietario puede hacer esto" |

### Test 3: Non-owner cannot read (returns 0)

| Step | Action | Details |
|---|---|---|
| 1 | Stay on account 2 | |
| 2 | Call `get` | Should return `0` (not the writer) |

### Test 4: Check who is the owner

| Step | Action | Details |
|---|---|---|
| 1 | Call `verPropietario` | Should return the address of account 1 (the deployer) |

### Test 5: Owner is permanent

| Step | Action | Details |
|---|---|---|
| 1 | Switch to account 2 | |
| 2 | Call `set` | Reverts (only owner) |
| 3 | The owner never changes | Unlike `escritor` which changes on every `set`, `propietario` is `immutable` and always stays as the deployer |

---

## Quick Reference: Common Mistakes

| Problem | Solution |
|---|---|
| Multiplying always gives 0 | The initial value is 0 and 0 times anything is 0. Use Storage6 or Storage7 with a constructor value |
| "Solo el propietario puede hacer esto" | Switch to the account that deployed the contract |
| Cannot see the gas difference | Look at the console below. Click on the transaction to expand the details. Compare transaction cost between set and the pure/view functions |
| setUint8 with 256 reverts | Max value for uint8 is 255. Each type has a maximum: uint8=255, uint16=65535, etc |
| get returns 0 on Storage5/6/7 | You are not the writer. Switch to the account that last called set |
| Forgot constructor parameter | Put the value next to the Deploy button before clicking Deploy |