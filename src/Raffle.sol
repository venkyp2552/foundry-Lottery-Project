// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


/**
 * @title A Sample Raffle Contract
 * @author Venkaiah P
 * @notice This contract is for creating simple Raflle 
 * @dev implements Chaninlink VRFv2.5
 */

contract Raffle {
    error Raffle__SendMoreToEnterRaffle();
    uint256 private immutable i_entranceFee;
    address payable [] private s_palyers;

    /**Events */
    event RaffleEnter(address indexed player);

    constructor(uint256 entrancefee){
        i_entranceFee=entrancefee;
    }

    function enterRaffle() public payable{
        // require(msg.value >=i_entranceFee,Raffle__SendMoreToEnterRaffle()); this is not suggestbale due to gas efficeint
        if(msg.value < i_entranceFee){
            revert Raffle__SendMoreToEnterRaffle();
        }
        s_palyers.push(payable(msg.sender));
        emit RaffleEnter(msg.sender)
    }

    function pinkWinner() public{

    }

    /**Getter Functions */
    function getEntranceFee() external view returns(uint256){
        return i_entranceFee;
    }
}
