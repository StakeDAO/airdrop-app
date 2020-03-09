pragma solidity ^0.4.24;

contract ICycleManager {

    bytes32 constant public UPDATE_CYCLE_ROLE = keccak256("UPDATE_CYCLE_ROLE");
    bytes32 constant public START_CYCLE_ROLE = keccak256("START_CYCLE_ROLE");

    uint256 public cycleLength;

    function initialize(uint256 _cycleLength) public;

    function startNextCycle() external;

    function currentCycleEndTime() public view returns (uint256);
}
