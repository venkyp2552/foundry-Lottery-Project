// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Script} from "lib/forge-std/src/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {CreateSubscription,FundSubscription,AddConsumer} from "../script/Interactions.s.sol";

contract DeployRaffle is Script{

    function deployContract() public returns(Raffle,HelperConfig){
        HelperConfig helperConfig=new HelperConfig();
        //1.if we are in local networks, get mocks
        //2.Sepolia => get sepolia config
        HelperConfig.NetworkConfig memory config=helperConfig.getConfig();
        if(config.subscriptionId==0){
            CreateSubscription createSubscription=new CreateSubscription();
            (config.subscriptionId,config.vrfCoordinator)=createSubscription.createSubscription(config.vrfCoordinator);

            //Fund it
            FundSubscription fundSubscription=new FundSubscription();
            fundSubscription.fundSubscription(config.vrfCoordinator,config.subscriptionId,config.link);
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

        AddConsumer addConsumer=new AddConsumer();
        //dont need broadcast here..
        addConsumer.addConsumer(address(raffle),config.vrfCoordinator,config.subscriptionId);
        return (raffle,helperConfig);
    }

    function run() external {
        deployContract();
    }
}

