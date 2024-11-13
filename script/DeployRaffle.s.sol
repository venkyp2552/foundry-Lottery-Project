// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Script} from "lib/forge-std/src/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {CreateSubscription} from "../script/Interactions.s.sol";
contract DeployRaffle is Script{

    function deployContract() public returns(Raffle,HelperConfig){
        HelperConfig helperConfig=new HelperConfig();
        //1.if we are in local networks, get mocks
        //2.Sepolia => get sepolia config
        HelperConfig.NetworkConfig memory config=helperConfig.getConfig();
        if(config.subscriptionId==0){
            CreateSubscription createSubscription=new CreateSubscription();
            (config.subscriptionId,config.vrfCoordinator)=createSubscription.createSubscription(config.vrfCoordinator);
        }
        vm.startBroadcast();
        Raffle raffle=new Raffle(
             config.entranceFee,
             config.interval,
             config.vrfCoordinator,
             config.gasLane,
             config.subscriptionId,
             config.callbackGasLimit
        );
        vm.stopBroadcast();
        return (raffle,helperConfig);
    }

    // function run() external {
    //     Raffle depluRaffle;
    //     uint256 entranceFee = 0.1 ether;
    //     vm.startBroadcast();
    //     depluRaffle=new Raffle(entranceFee);
    //     vm.stopBroadcast();
    // }
}
