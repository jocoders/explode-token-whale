// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.4.25;

/// @title A simple ERC20 Token Contract for the Token Whale Challenge
/// @notice This contract simulates a token with the goal of accumulating a large number of tokens
/// @dev This contract uses basic ERC20 functionalities with added challenge mechanics
contract TokenWhaleChallenge {
  address player;

  uint256 public totalSupply;
  mapping(address => uint256) public balanceOf;
  mapping(address => mapping(address => uint256)) public allowance;

  string public name = 'Simple ERC20 Token';
  string public symbol = 'SET';
  uint8 public decimals = 18;

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event DebugBalances(string stage, address from, uint256 fromBalance, address to, uint256 toBalance);
  event Transfer(address indexed from, address indexed to, uint256 value);

  /// @notice Checks if the player has accumulated at least 1,000,000 tokens
  /// @return true if the player's balance is at least 1,000,000 tokens
  function isComplete() public view returns (bool) {
    return balanceOf[player] >= 1000000;
  }

  /// @notice Initializes the contract with the total supply and assigns it to the player
  /// @param _player The address of the player who will receive the initial supply
  function TokenWhaleChallenge(address _player) public {
    player = _player;
    totalSupply = 1000;
    balanceOf[player] = 1000;
  }

  /// @notice Transfers tokens to a specified address
  /// @param to The address to transfer to
  /// @param value The amount of tokens to be transferred
  /// @dev Requires that the sender has enough tokens and that the transfer does not cause overflow
  function transfer(address to, uint256 value) public {
    require(balanceOf[msg.sender] >= value);
    require(balanceOf[to] + value >= balanceOf[to]);

    _transfer(to, value);
  }

  /// @notice Approves another address to spend tokens on behalf of the msg.sender
  /// @param spender The address which is approved to spend the tokens
  /// @param value The amount of tokens they are approved to spend
  function approve(address spender, uint256 value) public {
    allowance[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
  }

  /// @notice Transfers tokens from one address to another
  /// @param from The address which you want to send tokens from
  /// @param to The address which you want to transfer to
  /// @param value The amount of tokens to be transferred
  /// @dev Requires that the from address has enough tokens, the to address can receive the tokens without overflow, and the msg.sender is approved to spend the specified amount from the from address
  function transferFrom(address from, address to, uint256 value) public {
    require(balanceOf[from] >= value);
    require(balanceOf[to] + value >= balanceOf[to]);
    require(allowance[from][msg.sender] >= value);

    allowance[from][msg.sender] -= value;
    _transfer(to, value);
  }

  /// @dev Internal function to handle token transfers
  /// @param to The address of the recipient
  /// @param value The amount of tokens to transfer
  function _transfer(address to, uint256 value) internal {
    balanceOf[msg.sender] -= value;
    balanceOf[to] += value;

    emit Transfer(msg.sender, to, value);
  }
}
