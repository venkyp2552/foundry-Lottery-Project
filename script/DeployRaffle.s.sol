// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {Script} from "lib/forge-std/src/Script.sol";
import {Raffle} from "../src/Raffle.sol";

contract DeployRaffle is Script{
    function run() external {
        Raffle depluRaffle;
        uint256 entranceFee = 0.1 ether;
        vm.startBroadcast();
        depluRaffle=new Raffle(entranceFee);
        vm.stopBroadcast();
    }
}