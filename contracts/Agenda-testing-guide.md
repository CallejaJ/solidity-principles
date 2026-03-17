# Agenda Contracts - Testing Guide (Remix IDE)

## General Setup

Use the **Deploy & Run Transactions** tab. Environment: **Remix VM**. Each test account has 100 ETH. Use the **ACCOUNT** dropdown to switch between users.

Tip: copy a couple of account addresses before starting, you will need them to add as contacts.

---

## Agenda1 - Basic Contact Book

### Deploy

Select `Agenda1` and click Deploy. No parameters needed.

### Test 1: Add and read contacts

| Step | Action | Details |
|---|---|---|
| 1 | Call `addContact` | Parameters: `0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, "Pepe"` |
| 2 | Call `addContact` | Parameters: `0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, "Ana"` |
| 3 | Call `totalContacts` | Should return `2` |
| 4 | Call `getContact` | Parameter: `0` — should return the address and `"Pepe"` |
| 5 | Call `getContact` | Parameter: `1` — should return the address and `"Ana"` |

### Test 2: Contact that does not exist

| Step | Action | Details |
|---|---|---|
| 1 | Call `getContact` | Parameter: `5` |
| 2 | Expected result | Reverts with "That contact does not exist" |

---

## Agenda2 - Per-User Contact Book

### Deploy

Select `Agenda2` and click Deploy. No parameters needed.

### Test 1: Each user has their own book

| Step | Action | Details |
|---|---|---|
| 1 | Stay on account 1 | |
| 2 | Call `addContact` | Parameters: `0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, "Pepe"` |
| 3 | Call `totalContacts` | Should return `1` |
| 4 | Switch to account 2 in the ACCOUNT dropdown | |
| 5 | Call `totalContacts` | Should return `0` (account 2 has no contacts) |

### Test 2: Second user adds their own contact

| Step | Action | Details |
|---|---|---|
| 1 | Stay on account 2 | |
| 2 | Call `addContact` | Parameters: `0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, "Luis"` |
| 3 | Call `totalContacts` | Should return `1` |
| 4 | Call `getContact` | Parameter: `0` — should return `"Luis"` |
| 5 | Switch back to account 1 | |
| 6 | Call `getContact` | Parameter: `0` — should still return `"Pepe"` |

---

## Agenda3 - Edit and Delete

### Deploy

Select `Agenda3` and click Deploy. No parameters needed.

### Test 1: Add contacts

| Step | Action | Details |
|---|---|---|
| 1 | Call `addContact` | `0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, "Pepe"` |
| 2 | Call `addContact` | `0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, "Ana"` |
| 3 | Call `addContact` | `0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB, "Luis"` |
| 4 | Call `totalContacts` | Should return `3` |

### Test 2: Edit a contact

| Step | Action | Details |
|---|---|---|
| 1 | Call `editContact` | Parameters: `0, 0xdD870fA1b7C4700F2BD7f44238821C26f7392148, "Pedro"` |
| 2 | Call `getContact` | Parameter: `0` — should return the new address and `"Pedro"` |
| 3 | Call `getContact` | Parameter: `1` — should still be `"Ana"` (untouched) |

### Test 3: Delete a contact (swap and pop)

| Step | Action | Details |
|---|---|---|
| 1 | Call `deleteContact` | Parameter: `0` (deletes "Pedro") |
| 2 | Call `totalContacts` | Should return `2` |
| 3 | Call `getContact` | Parameter: `0` — should now be `"Luis"` (the last one moved to the empty spot) |
| 4 | Call `getContact` | Parameter: `1` — should still be `"Ana"` |

### Test 4: Delete the last contact

| Step | Action | Details |
|---|---|---|
| 1 | Call `deleteContact` | Parameter: `1` (deletes "Ana", the last one) |
| 2 | Call `totalContacts` | Should return `1` |
| 3 | Call `getContact` | Parameter: `0` — should be `"Luis"` |

### Test 5: Edit a contact that does not exist

| Step | Action | Details |
|---|---|---|
| 1 | Call `editContact` | Parameters: `10, 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, "Test"` |
| 2 | Expected result | Reverts with "That contact does not exist" |

---

## Agenda4 - Time-Limited Delegation

### Deploy

Select `Agenda4` and click Deploy. No parameters needed.

Note: in this version `totalContacts` and `getContact` need an `_owner` address as the first parameter.

### Test 1: Add contacts and read your own

| Step | Action | Details |
|---|---|---|
| 1 | Copy account 1 address | You will need it later |
| 2 | Call `addContact` | `0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, "Pepe"` |
| 3 | Call `totalContacts` | Parameter: your own address (account 1) — should return `1` |
| 4 | Call `getContact` | Parameters: your own address, `0` — should return `"Pepe"` |

### Test 2: Another user cannot see your contacts

| Step | Action | Details |
|---|---|---|
| 1 | Copy account 2 address | |
| 2 | Switch to account 2 | |
| 3 | Call `totalContacts` | Parameter: account 1 address |
| 4 | Expected result | Reverts with "You don't have permission to see this book" |

### Test 3: Grant read access

| Step | Action | Details |
|---|---|---|
| 1 | Switch back to account 1 | |
| 2 | Call `grantAccess` | Parameters: account 2 address, `300` (300 seconds = 5 min) |
| 3 | Call `hasAccess` | Parameters: account 1 address, account 2 address — should return `true` |

### Test 4: Delegated user can now read

| Step | Action | Details |
|---|---|---|
| 1 | Switch to account 2 | |
| 2 | Call `totalContacts` | Parameter: account 1 address — should return `1` |
| 3 | Call `getContact` | Parameters: account 1 address, `0` — should return `"Pepe"` |

### Test 5: Delegated user cannot edit or delete

| Step | Action | Details |
|---|---|---|
| 1 | Stay on account 2 | |
| 2 | Call `editContact` | Parameters: `0, 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB, "Hacked"` |
| 3 | Expected result | This edits account 2's own book (which is empty), NOT account 1's. The delegation is read-only because `editContact` uses `msg.sender` |

### Test 6: Revoke access

| Step | Action | Details |
|---|---|---|
| 1 | Switch to account 1 | |
| 2 | Call `revokeAccess` | Parameter: account 2 address |
| 3 | Call `hasAccess` | Parameters: account 1 address, account 2 address — should return `false` |
| 4 | Switch to account 2 | |
| 5 | Call `totalContacts` | Parameter: account 1 address |
| 6 | Expected result | Reverts with "You don't have permission to see this book" |

### Test 7: Account with no permission (account 3)

| Step | Action | Details |
|---|---|---|
| 1 | Switch to account 3 (never had access) | |
| 2 | Call `getContact` | Parameters: account 1 address, `0` |
| 3 | Expected result | Reverts with "You don't have permission to see this book" |

---

## Agenda5 - Search

### Deploy

Select `Agenda5` and click Deploy. No parameters needed.

### Test 1: Setup contacts for searching

| Step | Action | Details |
|---|---|---|
| 1 | Copy your own address (account 1) | |
| 2 | Call `addContact` | `0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, "Pepe"` |
| 3 | Call `addContact` | `0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, "Ana"` |
| 4 | Call `addContact` | `0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB, "Luis"` |

### Test 2: Search by address

| Step | Action | Details |
|---|---|---|
| 1 | Call `searchByAddress` | Parameters: your address, `0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2` |
| 2 | Expected result | `found: true, index: 0, name: "Pepe"` |

### Test 3: Search by address not found

| Step | Action | Details |
|---|---|---|
| 1 | Call `searchByAddress` | Parameters: your address, `0xdD870fA1b7C4700F2BD7f44238821C26f7392148` |
| 2 | Expected result | `found: false, index: 0, name: ""` |

### Test 4: Search by name

| Step | Action | Details |
|---|---|---|
| 1 | Call `searchByName` | Parameters: your address, `"Ana"` |
| 2 | Expected result | `found: true, index: 1, addr: 0x4B2...02db` |

### Test 5: Search by name not found

| Step | Action | Details |
|---|---|---|
| 1 | Call `searchByName` | Parameters: your address, `"Carlos"` |
| 2 | Expected result | `found: false, index: 0, addr: 0x000...000` |

### Test 6: Search is case sensitive

| Step | Action | Details |
|---|---|---|
| 1 | Call `searchByName` | Parameters: your address, `"pepe"` (lowercase) |
| 2 | Expected result | `found: false` — because it was saved as `"Pepe"` with capital P. The keccak256 hash is different |

### Test 7: Delegated user can search

| Step | Action | Details |
|---|---|---|
| 1 | On account 1, call `grantAccess` | Parameters: account 2 address, `300` |
| 2 | Switch to account 2 | |
| 3 | Call `searchByName` | Parameters: account 1 address, `"Luis"` |
| 4 | Expected result | `found: true, index: 2` |

### Test 8: Non-authorized user cannot search

| Step | Action | Details |
|---|---|---|
| 1 | Switch to account 3 | |
| 2 | Call `searchByName` | Parameters: account 1 address, `"Pepe"` |
| 3 | Expected result | Reverts with "You don't have permission to see this book" |

---

## Quick Reference: Common Mistakes

| Problem | Solution |
|---|---|
| "That contact does not exist" | The index is too high. Contacts go from 0 to totalContacts-1 |
| "You don't have permission" | You are trying to read someone else's book without delegation |
| Search returns false but contact exists | Check uppercase/lowercase. Search is case sensitive |
| editContact does not edit other user's contacts | That is correct. editContact always uses msg.sender so delegation is read-only |
| Forgot to copy the address | In Remix click the copy icon next to the account dropdown |
| Strings need quotes | Always put names in quotes: `"Pepe"` not `Pepe` |