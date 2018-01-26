pragma solidity ^0.4.4;

import "./Stopable.sol";

contract RockPaperScissor is Stopable {
uint gameid;

  struct Game {
    address player1;
    address player2;
    address winner;
    uint deadlinePlayer2;
    uint deadlineRevealMove;
    uint stake;
    bytes32 player1HashedMove;
    bytes32 player2HashedMove;
    uint player1Move;
    uint player2Move;
    bool winnerDetermined;
  }

mapping (uint => Game) games;
mapping (bytes32 => bool) usedPasswords;
mapping (address => uint) withdrawals;

event LogGameCreation(address player1, address player2, uint stake, uint deadlinePlayer2, uint deadlineRevealMove, uint gameid);
event LogPlayer2MoveSent(address player, uint playerMove);
event LogRevealSent(address player, uint playermove);
event LogWinner(address winner);
event LogWithdrawal(uint amount, address withdrawer);
event LogHash(bytes32);

  function RockPaperScissor() {
      running = true;
    // constructor
  }

//start a new game with 2 players and send the stake with it
  function startNewGame (address _player2, bytes32 _player1HashedMove, uint _deadlinePlayer2, uint _deadlineRevealMove)
  onlyIfRunning
  payable
  public
  { 
    uint id = gameid+1;
    require(_player2 != msg.sender);
    require(_player2 != address(0));
    require(msg.value > 0);
    require(_deadlinePlayer2 > 0);
    require(_deadlineRevealMove > _deadlinePlayer2+2);
    games[id].player1 = msg.sender;
    games[id].player2 = _player2;
    games[id].deadlinePlayer2 = _deadlinePlayer2;
    games[id].stake = msg.value;
    games[id].player1HashedMove = _player1HashedMove;
    LogGameCreation(msg.sender, _player2, msg.value, _deadlinePlayer2, _deadlineRevealMove, id);
  }

//both players should send in their hashed playermove before the deadline. PlayerMoveHash should contain a uint between 1 and 3 and a secret password
  function player2SendMove(uint _gameid, uint _player2Move)
  payable
  {
      //send 1) Rock   2) Paper   3)Scissor
    //require (now <= games[_gameid].deadlinePlayer2);
    require (msg.sender == games[_gameid].player2);
    require (games[_gameid].player2Move == 0);
    require (msg.value == games[_gameid].stake);
    games[_gameid].player2Move = _player2Move;
    games[_gameid].stake += msg.value;
    LogPlayer2MoveSent(msg.sender, _player2Move);
  }

  function checkPlayer2Move(uint _gameid){
   // require (now > games[_gameid].deadlinePlayer2);
    address player1 = games[_gameid].player1;
    if (games[_gameid].player2Move == 0){
        withdrawals[player1] = games[_gameid].stake;
    }
  }

  //after deadline: players should send in their revealed playermove before the second deadline. If they don't send it in, the playermove value will equal to 0 and they will loose.
  function sendPlayer1Move(uint _gameid, uint _playermove, bytes32 _password)
  {
    //require (now > games[_gameid].deadlinePlayer2);
    //require (now <= games[_gameid].deadlineRevealMove);
    bytes32 hashedPlayerMove = keccak256(_playermove, _password);
    LogHash(hashedPlayerMove);
    require(hashedPlayerMove == games[_gameid].player1HashedMove);
    games[_gameid].player1Move = _playermove;
    LogRevealSent(msg.sender, _playermove);  
  }

  //determine winner
  function determineWinner(uint _gameid)
  {
    require (!games[_gameid].winnerDetermined);
    //require (now > games[_gameid].deadlineRevealMove);
    address player1 = games[_gameid].player1;
    address player2 = games[_gameid].player2;
  
  if (games[_gameid].player1Move%3+1 == games[_gameid].player2Move){
   withdrawals[player2] = games[_gameid].stake;
   games[_gameid].winner = player2;
   LogWinner(games[_gameid].winner);
  }
  else if (games[_gameid].player2Move%3+1 == games[_gameid].player1Move){
    withdrawals[player1] = games[_gameid].stake;
    games[_gameid].winner = player1;
    LogWinner(games[_gameid].winner);
  }
  else {
    withdrawals[player1] = games[_gameid].stake/2;
    withdrawals[player2] = games[_gameid].stake/2;
  }
  games[_gameid].winnerDetermined=true;
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
