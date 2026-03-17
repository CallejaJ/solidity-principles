# EV Charging - Testing Guide (Remix IDE)

## General Setup

Before testing any contract, make sure you are in the **Deploy & Run Transactions** tab (Ethereum icon with arrow on the left panel).

Use **Remix VM** as the environment. You will see a list of test accounts at the top in the **ACCOUNT** dropdown. Each account has 100 ETH.

To send WEI with a transaction, use the **VALUE** field above the Deploy button. Set the amount and make sure the unit dropdown says **Wei** (not Ether).

---

## EVCharging1 - Base Contract

### Deploy

Select `EVCharging1` in the contract dropdown and put this next to the Deploy button:

```
20, 1000
```

That creates 20 chargers at 1000 WEI per minute.

### Test 1: Check initial values

| Action | Expected Result |
|---|---|
| Click `admin` | Shows the address of the account that deployed |
| Click `costPerMin` | Shows `1000` |
| Click `totalChargers` | Shows `20` |
| Click `getBalance` | Shows `0` (no money yet) |

### Test 2: Withdraw with no funds

| Action | Expected Result |
|---|---|
| Click `withdraw` | Reverts with "No funds to withdraw" |

### Test 3: Withdraw from non-admin account

| Action | Expected Result |
|---|---|
| Change to a different account in the ACCOUNT dropdown | |
| Click `withdraw` | Reverts with "Only admin can do this" |

---

## EVCharging2 - Prepaid Model

### Deploy

Select `EVCharging2` and put this next to the Deploy button:

```
20, 1000, 5, 60
```

That means: 20 chargers, 1000 WEI/min, minimum 5 min, maximum 60 min.

### Test 1: Reserve a charger

| Step | Action | Details |
|---|---|---|
| 1 | Set VALUE field | `10000` Wei (that covers 10 min at 1000 WEI/min) |
| 2 | Call `startCharging` | Parameters: `0, 10` (charger 0, 10 min) |
| 3 | Check the logs | You should see a `ChargingStarted` event in the console |
| 4 | Call `isAvailable` | Parameter: `0` — should return `false` |
| 5 | Call `getBalance` | Should return `10000` |

### Test 2: Try to use a busy charger

| Step | Action | Details |
|---|---|---|
| 1 | Set VALUE field | `10000` Wei |
| 2 | Change to a different ACCOUNT | |
| 3 | Call `startCharging` | Parameters: `0, 10` |
| 4 | Expected result | Reverts with "Charger is busy" |

### Test 3: Use a different charger with second account

| Step | Action | Details |
|---|---|---|
| 1 | Set VALUE field | `5000` Wei (5 min) |
| 2 | Stay on the second account | |
| 3 | Call `startCharging` | Parameters: `1, 5` (charger 1, 5 min) |
| 4 | Expected result | Success, `ChargingStarted` event emitted |
| 5 | Call `getBalance` | Should return `15000` (10000 + 5000) |

### Test 4: Below minimum time

| Step | Action | Details |
|---|---|---|
| 1 | Set VALUE field | `2000` Wei |
| 2 | Call `startCharging` | Parameters: `2, 2` (charger 2, 2 min — below the 5 min minimum) |
| 3 | Expected result | Reverts with "Below minimum time" |

### Test 5: Above maximum time

| Step | Action | Details |
|---|---|---|
| 1 | Set VALUE field | `100000` Wei |
| 2 | Call `startCharging` | Parameters: `2, 100` (100 min — above the 60 min max) |
| 3 | Expected result | Reverts with "Above maximum time" |

### Test 6: Not enough WEI

| Step | Action | Details |
|---|---|---|
| 1 | Set VALUE field | `1000` Wei (only covers 1 min) |
| 2 | Call `startCharging` | Parameters: `2, 10` (asking for 10 min) |
| 3 | Expected result | Reverts with "Not enough WEI sent" |

### Test 7: Overpayment returns change

| Step | Action | Details |
|---|---|---|
| 1 | Note your account balance before | |
| 2 | Set VALUE field | `50000` Wei |
| 3 | Call `startCharging` | Parameters: `2, 10` (costs 10000 WEI) |
| 4 | Expected result | Success. The contract keeps 10000 and returns 40000 |
| 5 | Call `getBalance` | Should have increased by only 10000 |

### Test 8: Stop charging manually

| Step | Action | Details |
|---|---|---|
| 1 | Use the account that reserved charger 0 | |
| 2 | Call `stopCharging` | Parameter: `0` |
| 3 | Expected result | Success, `ChargingEnded` event emitted |
| 4 | Call `isAvailable` | Parameter: `0` — should return `true` |

### Test 9: Stop someone else's charger

| Step | Action | Details |
|---|---|---|
| 1 | Change to a different account | |
| 2 | Call `stopCharging` | Parameter: `1` (charger reserved by another user) |
| 3 | Expected result | Reverts with "Not your charger" |

### Test 10: Charger that does not exist

| Step | Action | Details |
|---|---|---|
| 1 | Call `isAvailable` | Parameter: `25` (we only have 20 chargers, 0-19) |
| 2 | Expected result | Reverts with "Charger does not exist" |

### Test 11: Admin withdraws funds

| Step | Action | Details |
|---|---|---|
| 1 | Switch back to the admin account (the one that deployed) | |
| 2 | Call `getBalance` | Note the contract balance |
| 3 | Call `withdraw` | Success |
| 4 | Call `getBalance` | Should return `0` |

---

## EVCharging3 - Postpaid Model

### Deploy

Select `EVCharging3` and put this next to the Deploy button:

```
20, 1000
```

That means: 20 chargers, 1000 WEI per minute.

### Test 1: Start charging (free to connect)

| Step | Action | Details |
|---|---|---|
| 1 | Make sure VALUE is `0` | No payment needed to start |
| 2 | Call `startCharging` | Parameter: `0` (charger 0) |
| 3 | Expected result | Success, `ChargingStarted` event in the logs |
| 4 | Call `isAvailable` | Parameter: `0` — should return `false` |

### Test 2: Check time and cost while charging

| Step | Action | Details |
|---|---|---|
| 1 | Call `getUsedMins` | Parameter: `0` — shows how long you have been charging |
| 2 | Call `getCurrentCost` | Parameter: `0` — shows what you would pay right now |
| 3 | Note | In Remix VM time does not pass between calls, so it will show 0 min and 1000 WEI (minimum 1 min). In a real blockchain, time would pass and the cost would go up |

### Test 3: Stop and pay

| Step | Action | Details |
|---|---|---|
| 1 | Call `getCurrentCost` | Parameter: `0` — note the amount |
| 2 | Set VALUE field | Put at least the amount from step 1 (e.g. `1000` Wei) |
| 3 | Call `stopCharging` | Parameter: `0` |
| 4 | Expected result | Success, `ChargingEnded` event with minutes used and total cost |
| 5 | Call `isAvailable` | Parameter: `0` — should return `true` |
| 6 | Call `getBalance` | Should show the WEI that was paid |

### Test 4: Try to stop without enough WEI

| Step | Action | Details |
|---|---|---|
| 1 | Call `startCharging` | Parameter: `0` |
| 2 | Set VALUE field | `0` Wei |
| 3 | Call `stopCharging` | Parameter: `0` |
| 4 | Expected result | Reverts with "Not enough WEI sent" |

### Test 5: Try to use a busy charger

| Step | Action | Details |
|---|---|---|
| 1 | First account starts charging on charger 3 | `startCharging(3)` |
| 2 | Change to a different account | |
| 3 | Call `startCharging` | Parameter: `3` |
| 4 | Expected result | Reverts with "Charger is busy" |

### Test 6: Try to stop someone else's charger

| Step | Action | Details |
|---|---|---|
| 1 | Stay on the second account | |
| 2 | Set VALUE to `1000` Wei | |
| 3 | Call `stopCharging` | Parameter: `3` (charger of the first account) |
| 4 | Expected result | Reverts with "Not your charger" |

### Test 7: Non-admin cannot withdraw

| Step | Action | Details |
|---|---|---|
| 1 | Stay on a non-admin account | |
| 2 | Call `withdraw` | |
| 3 | Expected result | Reverts with "Only admin can do this" |

### Test 8: Admin withdraws

| Step | Action | Details |
|---|---|---|
| 1 | Switch to the admin account | |
| 2 | Call `getBalance` | Note the amount |
| 3 | Call `withdraw` | Success |
| 4 | Call `getBalance` | Should return `0` |

---

## Quick Reference: Common Mistakes

| Problem | Solution |
|---|---|
| "Error encoding arguments" on deploy | You forgot to put the constructor parameters next to the Deploy button |
| "Not enough WEI sent" | Set the VALUE field above the Deploy button before calling the function |
| VALUE is in Ether instead of Wei | Change the dropdown next to the VALUE field to Wei |
| "Only admin can do this" | Switch back to the account that deployed the contract |
| "Charger is busy" | That charger is already in use. Try a different charger number |
| "Charger does not exist" | Charger IDs go from 0 to totalChargers-1 (e.g. 0 to 19 for 20 chargers) |
| Time does not pass in Remix VM | Normal. Remix VM processes everything instantly. On a real blockchain time would pass between blocks |