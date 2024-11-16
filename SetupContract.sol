pragma solidity ^0.4.25;

import { TokenWhaleChallenge } from './TokenWhaleChallenge.sol';

contract Bob {
  TokenWhaleChallenge public token;

  address private owner;

  constructor(TokenWhaleChallenge _token) {
    token = _token;
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, 'Only owner can call this function');
    _;
  }

  function approveForSender(uint256 amount) public onlyOwner {
    token.approve(msg.sender, amount);
  }
}

contract SetupContract {
  TokenWhaleChallenge public token;
  Bob public bob;

  address public Alice = address(0x01);
  address public PLAYER = address(this);

  //event Balance(uint256 balance);
  event Balances(uint256 balancePlayer, uint256 balanceAlice, uint256 balanceBob);
  event Amounts(uint256 amount1, uint256 amount2);
  event Adresses(address player, address thisAddress, address bobAddress);

  function setup() public {
    token = new TokenWhaleChallenge(PLAYER);
    bob = new Bob(token);
  }

  function test_approve(address spender, uint256 amount) public {
    token.approve(spender, amount);
    uint256 approve = token.allowance(PLAYER, spender);
    assert(approve == amount);
  }

  function test_transfer(uint256 amount) public {
    uint256 balancePlayerBefore = token.balanceOf(PLAYER);
    uint256 balanceAliceBefore = token.balanceOf(Alice);

    token.approve(Alice, amount);
    token.transfer(Alice, amount);

    uint256 balanceAliceAfter = token.balanceOf(Alice);
    uint256 balancePlayerAfter = token.balanceOf(PLAYER);

    emit Balances(balancePlayerAfter, balanceAliceAfter, amount);
    assert(balanceAliceAfter == balanceAliceBefore + amount && balancePlayerAfter == balancePlayerBefore - amount);
  }

  function test_transferFrom_static() public {
    uint256 AMOUNT_1 = 900;
    uint256 balancePlayerInit = token.balanceOf(PLAYER);

    token.approve(address(bob), AMOUNT_1);
    token.transfer(address(bob), AMOUNT_1);

    uint256 AMOUNT_2 = 800;
    bob.approveForSender(AMOUNT_2);
    token.transferFrom(address(bob), Alice, AMOUNT_2);

    uint256 balancePlayerFinish = token.balanceOf(PLAYER);
    uint256 balanceAliceFinish = token.balanceOf(Alice);
    uint256 balanceBobFinish = token.balanceOf(address(bob));

    // emit Balances(balancePlayer=115792089237316195423570985008687907853269984665640564039457584007913129639236, balanceAlice=800, balanceBob=900)
    emit Balances(balancePlayerFinish, balanceAliceFinish, balanceBobFinish);

    assert(balancePlayerInit == balancePlayerFinish - AMOUNT_1);
  }

  function test_transferFrom_dynamic(uint256 amount1, uint256 amount2) public {
    uint256 balancePlayerInit = token.balanceOf(PLAYER);
    if (amount1 >= amount2) return;

    token.approve(address(bob), amount1);
    token.transfer(address(bob), amount1);

    bob.approveForSender(amount2);
    token.transferFrom(address(bob), Alice, amount2);

    uint256 balancePlayerFinish = token.balanceOf(PLAYER);
    uint256 balanceAliceFinish = token.balanceOf(Alice);
    uint256 balanceBobFinish = token.balanceOf(address(bob));

    emit Amounts(amount1, amount2);
    emit Balances(balancePlayerFinish, balanceAliceFinish, balanceBobFinish);

    assert(balancePlayerFinish == balancePlayerInit - amount1);
  }
}
