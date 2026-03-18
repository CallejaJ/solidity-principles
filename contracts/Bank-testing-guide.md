# Bank Contracts - Testing Guide (Remix IDE)

## General Setup

Use the **Deploy & Run Transactions** tab. Environment: **Remix VM**. Each test account starts with 100 ETH.

Important: to send ETH with a transaction, use the **VALUE** field above the Deploy button. Make sure the unit dropdown says the right unit (Wei, Gwei, or Ether).

Tip: 1 Ether = 1000000000000000000 Wei. For easier testing you can use the Ether dropdown and put `1` or `5`.

---

## Bank1 - Deposit, Withdraw, Check Balance

### Deploy

Select `Bank1` and click Deploy. No parameters needed.

### Test 1: Deposit ETH

| Step | Action | Details |
|---|---|---|
| 1 | Set VALUE field | `5` Ether (change the dropdown from Wei to Ether) |
| 2 | Call `deposit` | Success |
| 3 | Call `getMyBalance` | Should return `5000000000000000000` (5 ETH in Wei) |

### Test 2: Deposit from a second account

| Step | Action | Details |
|---|---|---|
| 1 | Switch to account 2 | |
| 2 | Set VALUE | `3` Ether |
| 3 | Call `deposit` | Success |
| 4 | Call `getMyBalance` | Should return 3 ETH in Wei |
| 5 | Switch to account 1 | |
| 6 | Call `getMyBalance` | Still shows 5 ETH — each account has its own balance |

### Test 3: Withdraw ETH

| Step | Action | Details |
|---|---|---|
| 1 | Set VALUE to `0` | Important: withdraw does not need VALUE |
| 2 | Call `withdraw` | Parameter: `2000000000000000000` (2 ETH in Wei) |
| 3 | Call `getMyBalance` | Should return 3 ETH in Wei (5 - 2 = 3) |

### Test 4: Withdraw more than balance

| Step | Action | Details |
|---|---|---|
| 1 | Call `withdraw` | Parameter: `10000000000000000000` (10 ETH) |
| 2 | Expected result | Reverts with "Not enough balance" |

### Test 5: Deposit zero

| Step | Action | Details |
|---|---|---|
| 1 | Set VALUE to `0` | |
| 2 | Call `deposit` | Reverts with "Must send some ETH" |

---

## Bank2 - Basic Loans

### Deploy

Select `Bank2` and click Deploy. No parameters needed.

### Test 1: Setup deposits

| Step | Action | Details |
|---|---|---|
| 1 | Account 1: set VALUE `10` Ether | |
| 2 | Call `deposit` | Bank now has 10 ETH |
| 3 | Switch to account 2 | |
| 4 | Set VALUE `5` Ether | |
| 5 | Call `deposit` | Bank now has 15 ETH |
| 6 | Call `getBankBalance` | Should return 15 ETH in Wei |

### Test 2: Borrow money

| Step | Action | Details |
|---|---|---|
| 1 | Switch to account 3 (has no deposit) | |
| 2 | Set VALUE to `0` | Borrowing does not require VALUE |
| 3 | Call `borrow` | Parameter: `2000000000000000000` (2 ETH) |
| 4 | Call `getDebt` | Parameter: account 3 address — should return 2 ETH in Wei |
| 5 | Call `isDebtor` | Parameter: account 3 address — should return `true` |
| 6 | Call `getBankBalance` | Should return 13 ETH (15 - 2 = 13) |

### Test 3: Repay part of the debt

| Step | Action | Details |
|---|---|---|
| 1 | Stay on account 3 | |
| 2 | Set VALUE `1` Ether | |
| 3 | Call `repay` | Success |
| 4 | Call `getDebt` | Parameter: account 3 address — should return 1 ETH |
| 5 | Call `isDebtor` | Should still return `true` (still owes 1 ETH) |

### Test 4: Repay full debt

| Step | Action | Details |
|---|---|---|
| 1 | Set VALUE `1` Ether | |
| 2 | Call `repay` | Success |
| 3 | Call `getDebt` | Parameter: account 3 address — should return `0` |
| 4 | Call `isDebtor` | Should return `false` (no longer a debtor) |

### Test 5: Overpay returns change

| Step | Action | Details |
|---|---|---|
| 1 | First borrow again: call `borrow` with `1000000000000000000` (1 ETH) | |
| 2 | Set VALUE `5` Ether | |
| 3 | Call `repay` | Success — pays 1 ETH debt, returns 4 ETH change |
| 4 | Call `getDebt` | Should return `0` |
| 5 | Call `isDebtor` | Should return `false` |

### Test 6: Liquidity problem

| Step | Action | Details |
|---|---|---|
| 1 | Account 3: call `borrow` with `12000000000000000000` (12 ETH) | |
| 2 | Switch to account 1 | |
| 3 | Call `withdraw` with `10000000000000000000` (10 ETH, their full deposit) | |
| 4 | Expected result | Reverts with "Bank does not have enough liquidity" — the bank lent out too much money |

### Test 7: Anyone can check any debt

| Step | Action | Details |
|---|---|---|
| 1 | From any account | |
| 2 | Call `getDebt` | Parameter: any address — debt info is public |

---

## Bank3 - Partial Withdrawals

### Deploy

Select `Bank3` and click Deploy. No parameters needed.

### Test 1: Setup and create liquidity problem

| Step | Action | Details |
|---|---|---|
| 1 | Account 1: deposit `10` Ether | |
| 2 | Account 2: deposit `5` Ether | Bank has 15 ETH |
| 3 | Account 3: borrow `12` ETH | Bank now has 3 ETH real |

### Test 2: Partial withdrawal when bank has less

| Step | Action | Details |
|---|---|---|
| 1 | Switch to account 1 | Balance is 10 ETH but bank only has 3 ETH |
| 2 | Call `getAvailableToWithdraw` | Should return 3 ETH (what the bank actually has) |
| 3 | Call `withdraw` with `10000000000000000000` (10 ETH) | |
| 4 | Expected result | Only 3 ETH is transferred (what the bank has). The remaining 7 ETH stays as balance in the contract |
| 5 | Call `getMyBalance` | Should return 7 ETH (10 - 3 = 7, the part not yet withdrawn) |
| 6 | Call `getBankBalance` | Should return `0` |

### Test 3: Debtor repays and depositor can withdraw the rest

| Step | Action | Details |
|---|---|---|
| 1 | Switch to account 3 | |
| 2 | Set VALUE `12` Ether | |
| 3 | Call `repay` | Bank now has 12 ETH again |
| 4 | Switch to account 1 | |
| 5 | Call `getAvailableToWithdraw` | Should return 7 ETH (the remaining balance) |
| 6 | Call `withdraw` with `7000000000000000000` | Success this time |

---

## Bank4 - Reserve Rate and Preloaded ETH

### Deploy

Select `Bank4`. Next to the Deploy button put:

```
5
```

That sets the reserve rate to 5%. Also set VALUE to `10` Ether before deploying — this preloads the bank with 10 ETH that belongs to nobody.

### Test 1: Check initial state

| Step | Action | Details |
|---|---|---|
| 1 | Call `getBankBalance` | Should return 10 ETH (the preloaded amount) |
| 2 | Call `reserveRate` | Should return `5` |
| 3 | Call `totalDeposits` | Should return `0` (preloaded ETH is not a deposit) |
| 4 | Call `getLoanableAmount` | Should return 10 ETH (no deposits yet, so no reserve needed from deposits) |

### Test 2: Deposit and check loanable amount

| Step | Action | Details |
|---|---|---|
| 1 | Account 1: deposit `100` Ether | |
| 2 | Call `totalDeposits` | Should return 100 ETH |
| 3 | Call `getBankBalance` | Should return 110 ETH (100 deposit + 10 preloaded) |
| 4 | Call `getLoanableAmount` | Reserve = 5% of 100 = 5 ETH. Loanable = 110 - 5 = 105 ETH |

### Test 3: Borrow respects the reserve

| Step | Action | Details |
|---|---|---|
| 1 | Account 2: call `borrow` with `105` Ether | Should work (within loanable amount) |
| 2 | Call `getBankBalance` | Should return 5 ETH (the reserve) |
| 3 | Call `getLoanableAmount` | Should return `0` (bank is at minimum reserve) |
| 4 | Account 3: call `borrow` with `1` Ether | Reverts with "Exceeds loanable amount" |

### Test 4: Depositor affected by loans

| Step | Action | Details |
|---|---|---|
| 1 | Switch to account 1 | Balance is 100 ETH |
| 2 | Call `getAvailableToWithdraw` | Should return 5 ETH (that is all the bank has) |
| 3 | Call `withdraw` with `100` Ether | Only 5 ETH transferred |
| 4 | Call `getMyBalance` | 95 ETH still pending |

---

## Bank5 - Personal Borrow Limit

### Deploy

Select `Bank5`. Put `5` next to Deploy. Set VALUE to `10` Ether to preload the bank.

### Test 1: No deposit means no borrow limit

| Step | Action | Details |
|---|---|---|
| 1 | Account 2 (no deposits): call `getMyBorrowLimit` | Should return `0` |
| 2 | Call `borrow` with `1000000000000000000` (1 ETH) | Reverts with "Exceeds your personal borrow limit" |

### Test 2: Deposit creates borrow limit

| Step | Action | Details |
|---|---|---|
| 1 | Account 1: deposit `20` Ether | |
| 2 | Call `getMyBorrowLimit` | Should return 20 ETH (max balance ever = 20 ETH) |
| 3 | Call `borrow` with `5` Ether | Success |
| 4 | Call `getMyBorrowLimit` | Should return 15 ETH (20 - 5 already borrowed) |
| 5 | Call `getDebt` | Parameter: account 1 — should return 5 ETH |

### Test 3: Borrow limit is based on max balance ever

| Step | Action | Details |
|---|---|---|
| 1 | Account 1: call `withdraw` with `15` Ether | Balance goes to 5 ETH |
| 2 | Call `getMyBorrowLimit` | Still 15 ETH (limit is based on max historical balance of 20, minus 5 debt) |
| 3 | Call `maxBalanceEver` | Parameter: account 1 — should return 20 ETH |

### Test 4: Cannot borrow more than personal limit

| Step | Action | Details |
|---|---|---|
| 1 | Account 1: call `borrow` with `16` Ether | Reverts with "Exceeds your personal borrow limit" (limit is 15) |
| 2 | Call `borrow` with `15` Ether | Success (exactly at the limit) |
| 3 | Call `getMyBorrowLimit` | Should return `0` |

### Test 5: Repaying restores borrow limit

| Step | Action | Details |
|---|---|---|
| 1 | Account 1: set VALUE to `10` Ether | |
| 2 | Call `repay` | Pays 10 of 20 ETH debt |
| 3 | Call `getMyBorrowLimit` | Should return 10 ETH (20 max - 10 remaining debt) |

### Test 6: New deposit increases max balance

| Step | Action | Details |
|---|---|---|
| 1 | Account 1: deposit `50` Ether | New balance = 5 + 50 = 55 ETH |
| 2 | Call `maxBalanceEver` | Parameter: account 1 — should return 55 ETH (updated because 55 > 20) |
| 3 | Call `getMyBorrowLimit` | Should return 45 ETH (55 max - 10 remaining debt) |

### Test 7: Both limits apply (reserve + personal)

| Step | Action | Details |
|---|---|---|
| 1 | Call `getLoanableAmount` | Check how much the bank can lend globally |
| 2 | Call `getMyBorrowLimit` | Check your personal limit |
| 3 | The actual max you can borrow | The smaller of the two values |

---

## Quick Reference: Common Mistakes

| Problem | Solution |
|---|---|
| "Must send some ETH" on deposit | Set the VALUE field before calling deposit |
| "Not enough balance" on withdraw | You are trying to withdraw more than you deposited |
| "Bank does not have enough liquidity" | The bank lent out too much money. Wait for debtors to repay |
| "Exceeds loanable amount" | The bank hit the reserve limit (5%). It must keep some ETH |
| "Exceeds your personal borrow limit" | You need to deposit more first. Your limit is based on your max historical balance |
| "You have no debt" on repay | You have nothing to repay |
| Withdraw gives less than expected | The bank does not have enough cash (Bank3+). Check getAvailableToWithdraw |
| Numbers are huge | Remix shows Wei. 1 Ether = 1000000000000000000 Wei (18 zeros) |
| VALUE not resetting | Remember to set VALUE back to 0 after deposit/repay, or you will accidentally send ETH on other calls |
| Forgot to preload ETH on deploy | For Bank4/Bank5: set VALUE to some Ether BEFORE clicking Deploy |