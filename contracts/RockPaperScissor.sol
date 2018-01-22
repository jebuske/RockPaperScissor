pragma solidity ^0.4.4;

import "./Stopable.sol";

contract RockPaperScissor is Stopable {

  struct Game {
    address player1;
    address player2;
    address winner;
    uint deadlineHashedMove;
    uint deadlineRevealMove;
    uint stake;
    bytes32 player1HashedMove;
    bytes32 player2HashedMove;
    uint player1Move;
    uint player2Move;
  }

mapping (uint => Game) games;
mapping (uint => bool) usedIds;
mapping (bytes32 => bool) usedPasswords;
mapping (address => uint) withdrawals;
mapping (uint => bool) winnerDeterimined;

event LogGameCreation(address player1, address player2, uint stake, uint deadlineHashedMove, uint deadlineRevealMove);
event LogHashedPlayermoveSent(address player, bytes32 hashedPlayerMove);
event LogRevealSent(address player, uint playermove);
event LogWinner(address winner);
event LogWithdrawal(uint amount, address withdrawer);

  function RockPaperScissor() {
      running = true;
    // constructor
  }

//start a new game with 2 players and send the stake with it
  function startNewGame (uint _id, address _player2, uint _deadlineHashedMove, uint _deadlineRevealMove)
  onlyIfRunning
  public
  payable
  {
    require(!usedIds[_id]);
    require(_player2 != msg.sender);
    require(msg.value > 0);
    require(_deadlineHashedMove > 0);
    require(_deadlineRevealMove > _deadlineHashedMove+2);
    
    games[_id].player1 = msg.sender;
    games[_id].player2 = _player2;
    games[_id].deadlineHashedMove = _deadlineHashedMove;
    games[_id].stake = msg.value;
    usedIds[_id] = true;
    LogGameCreation(msg.sender, _player2, msg.value, _deadlineHashedMove, _deadlineRevealMove);
  }

//both players should send in their hashed playermove before the deadline. PlayerMoveHash should contain a uint between 1 and 3 and a secret password
  function sendHashedPayerMove(uint _gameid, bytes32 _playerMoveHash)
  {
    require (now <= games[_gameid].deadlineHashedMove);
    require (!usedPasswords[_playerMoveHash]);
    if (msg.sender == games[_gameid].player1){
      require(games[_gameid].player1HashedMove == 0);
      games[_gameid].player1HashedMove = _playerMoveHash;
      usedPasswords[_playerMoveHash] = true;
    }
    if (msg.sender == games[_gameid].player2){
      require(games[_gameid].player2HashedMove == 0);
      games[_gameid].player1HashedMove = _playerMoveHash;
      usedPasswords[_playerMoveHash] = true;
      
    }
    LogHashedPlayermoveSent(msg.sender, _playerMoveHash);
  }

  //after deadline: players should send in their revealed playermove before the second deadline. If they don't send it in, the playermove value will equal to 0 and they will loose.
  function sendPlayerMove(uint _gameid, uint _playermove, bytes32 _password)
  {
    require (now > games[_gameid].deadlineHashedMove);
    require (now <= games[_gameid].deadlineRevealMove);
    bytes32 hashedPlayerMove = keccak256(_playermove, _password);
    if (msg.sender == games[_gameid].player1){
      require(hashedPlayerMove == games[_gameid].player1HashedMove);
      games[_gameid].player1Move = _playermove;
    }
     if (msg.sender == games[_gameid].player2){
     require(hashedPlayerMove == games[_gameid].player1HashedMove);
      games[_gameid].player2Move = _playermove;
    }
    LogRevealSent(msg.sender, _playermove);
  }

  //determine winner
  function determineWinner(uint _gameid)
  {
    require (!winnerDeterimined[_gameid]);
    require (now > games[_gameid].deadlineRevealMove);
  address player1 = games[_gameid].player1;
  address player2 = games[_gameid].player2;
  if (games[_gameid].player1Move == 0 && games[_gameid].player2Move == 0){
    withdrawals[player1] = games[_gameid].stake/2;
    withdrawals[player2] = games[_gameid].stake/2;
  }
  if (games[_gameid].player1Move == 0){
    withdrawals[player2] = games[_gameid].stake/2;
  }
  if (games[_gameid].player2Move == 0){
    withdrawals[player1] = games[_gameid].stake/2;
  }
  if (games[_gameid].player1Move%3+1 == games[_gameid].player2Move){
   withdrawals[player2] = games[_gameid].stake;
   LogWinner(player2);
  }
  if (games[_gameid].player2Move%3+1 == games[_gameid].player1Move){
    withdrawals[player1] = games[_gameid].stake;
    LogWinner(player1);
  }
  else {
    withdrawals[player1] = games[_gameid].stake/2;
    withdrawals[player2] = games[_gameid].stake/2;
  }
  winnerDeterimined[_gameid]=true;
  }
  
  function withdraw () returns (bool) {
    require(withdrawals[msg.sender]>0);
    uint amount = withdrawals[msg.sender];
    withdrawals[msg.sender] = 0;
    msg.sender.transfer(amount);
    LogWithdrawal(amount, msg.sender);
    return true;
  }

}
