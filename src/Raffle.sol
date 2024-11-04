// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


/**
 * @title A Sample Raffle Contract
 * @author Venkaiah P
 * @notice This contract is for creating simple Raflle 
 * @dev implements Chaninlink VRFv2.5
 */

contract Raffle {
    uint256 private immutable i_entranceFee;

    constructor(uint256 entrancefee){
        i_entranceFee=entrancefee;
    }

    function enterRaffle() public payable{

    }

    function pinkWinner() public{

    }

    /**Getter Functions */
    function getEntranceFee() external view returns(uint256){
        return i_entranceFee;
    }
}
