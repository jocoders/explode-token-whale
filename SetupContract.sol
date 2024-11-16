// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.4.25;

import { TokenWhaleChallenge } from './TokenWhaleChallenge.sol';

/// @title Bob Contract
/// @dev Simulates an external user for testing the TokenWhaleChallenge contract
contract Bob {
  TokenWhaleChallenge public token;

  address private owner;

  /// @dev Initializes the Bob contract
  /// @param _token The address of the TokenWhaleChallenge contract
  constructor(TokenWhaleChallenge _token) {
    token = _token;
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, 'Only owner can call this function');
    _;
  }

  /// @dev Approves tokens for the sender to spend
  /// @param amount The amount of tokens to approve
  function approveForSender(uint256 amount) public onlyOwner {
    token.approve(msg.sender, amount);
  }
}

/// @title Setup Contract for TokenWhaleChallenge
/// @dev Sets up and tests the TokenWhaleChallenge contract
contract SetupContract {
  TokenWhaleChallenge public token;
  Bob public bob;

  address public ALICE = address(0x01);
  address public PLAYER = address(this);

  event Amounts(uint256 amount1, uint256 amount2);
  event Balances(uint256 balancePlayer, uint256 balanceAlice, uint256 balanceBob);

  /// @dev Initializes the testing environment
  /// Deploys a new TokenWhaleChallenge and Bob contract
  function setup() public {
    token = new TokenWhaleChallenge(PLAYER);
    bob = new Bob(token);
  }

  /// @dev Tests approving tokens for a spender
  /// @param spender The address of the spender
  /// @param amount The amount of tokens to approve
  function test_approve(address spender, uint256 amount) public {
    token.approve(spender, amount);
    uint256 approve = token.allowance(PLAYER, spender);
    assert(approve == amount);
  }

  /// @dev Tests transferring tokens directly from PLAYER to ALICE
  /// @param amount The amount of tokens to transfer
  function test_transfer(uint256 amount) public {
    uint256 balancePlayerBefore = token.balanceOf(PLAYER);
    uint256 balanceAliceBefore = token.balanceOf(ALICE);

    token.approve(ALICE, amount);
    token.transfer(ALICE, amount);

    uint256 balanceAliceAfter = token.balanceOf(ALICE);
    uint256 balancePlayerAfter = token.balanceOf(PLAYER);

    emit Balances(balancePlayerAfter, balanceAliceAfter, amount);
    assert(balanceAliceAfter == balanceAliceBefore + amount && balancePlayerAfter == balancePlayerBefore - amount);
  }

  /// @dev Tests the transferFrom functionality with static values
  function test_transferFrom_static() public {
    uint256 AMOUNT_1 = 900;
    uint256 balancePlayerInit = token.balanceOf(PLAYER);

    token.approve(address(bob), AMOUNT_1);
    token.transfer(address(bob), AMOUNT_1);

    uint256 AMOUNT_2 = 800;
    bob.approveForSender(AMOUNT_2);
    token.transferFrom(address(bob), ALICE, AMOUNT_2);

    uint256 balancePlayerFinish = token.balanceOf(PLAYER);
    uint256 balanceAliceFinish = token.balanceOf(ALICE);
    uint256 balanceBobFinish = token.balanceOf(address(bob));

    // emit Balances(balancePlayer=115792089237316195423570985008687907853269984665640564039457584007913129639236, balanceAlice=800, balanceBob=900)
    emit Balances(balancePlayerFinish, balanceAliceFinish, balanceBobFinish);

    assert(balancePlayerInit == balancePlayerFinish - AMOUNT_1);
  }

  /// @dev Tests the transferFrom functionality with dynamic values
  /// @param amount1 The amount of tokens to transfer to Bob
  /// @param amount2 The amount of tokens Bob transfers to ALICE
  function test_transferFrom_dynamic(uint256 amount1, uint256 amount2) public {
    uint256 balancePlayerInit = token.balanceOf(PLAYER);
    if (amount1 >= amount2) return;

    token.approve(address(bob), amount1);
    token.transfer(address(bob), amount1);

    bob.approveForSender(amount2);
    token.transferFrom(address(bob), ALICE, amount2);

    uint256 balancePlayerFinish = token.balanceOf(PLAYER);
    uint256 balanceAliceFinish = token.balanceOf(ALICE);
    uint256 balanceBobFinish = token.balanceOf(address(bob));

    emit Amounts(amount1, amount2);
    emit Balances(balancePlayerFinish, balanceAliceFinish, balanceBobFinish);

    assert(balancePlayerFinish == balancePlayerInit - amount1);
  }
}
