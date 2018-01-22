pragma solidity ^0.4.18;

import "./Owned.sol";

contract Stopable is Owned {
  bool public running;

  modifier onlyIfRunning{
    if (running)_;
  }

  function stopable(){
    running = true;
  }

  function runSwitch(bool onOff)
  onlyOwner
  returns(bool success){
    running = onOff;
    return true;
  }
}