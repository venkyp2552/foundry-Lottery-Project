// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.18;
// import {Script} from "lib/forge-std/src/Script.sol";
// import {Raffle} from "../src/Raffle.sol";
// import {DeployRaffle} from "../script/DeployRaffle.s.sol";

// contract RaffleTest is Script{
//     Raffle public raffle;

//     function setUp() public{
//         raffle=new Raffle(0.1 ether);
//     }

//     function toTestEntraceFee() public view{
//         assert(raffle.getEntranceFee()==0.1 ether);
//     }

// }
