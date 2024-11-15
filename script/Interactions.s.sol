// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script,console} from "lib/forge-std/src/Script.sol";
import {HelperConfig,CodeConstants} from "../script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script{
    function createSubscriptionUsingConfig() public returns(uint256,address){
        HelperConfig helperConfig=new HelperConfig();
        address vrfCoordinator=helperConfig.getConfig().vrfCoordinator;
        (uint256 subId,)=createSubscription(vrfCoordinator);
        return (subId,vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator) public returns(uint256,address){
        console.log("Creating Subscrition on ChainId: ",block.chainid);
        vm.startBroadcast();
        uint256 subId=VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();
        console.log("Your Subscrption Id is : ",subId);
        console.log("Please update this SUbscription Id in your HelperConfig.s.sol");
        return (subId,vrfCoordinator);
    }

    function run() public{
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script,CodeConstants{
    uint256 public constant FUND_AMOUNT=3 ether; //3 LINKS

    function FundSubscriptionUsingConfig() public{
        HelperConfig helperConfig=new HelperConfig();
        address vrfCoordinator=helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId=helperConfig.getConfig().subscriptionId;
        address linkToken=helperConfig.getConfig().link;
        fundSubscription(vrfCoordinator,subscriptionId,linkToken);
    }

    function fundSubscription(address vrfCoordinator,uint256 subscriptionId,address linkToken) public{
        
        console.log("Using Subscription Id:",subscriptionId);
        console.log("Using VrfCoordinator Id:",vrfCoordinator);
        console.log("On Chain Id:",block.chainid);

        //Lets check based on the chainid

        if(block.chainid == LOCAL_CHAIN_ID){
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId,FUND_AMOUNT);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(vrfCoordinator,FUND_AMOUNT,abi.encode(subscriptionId));
            vm.stopBroadcast();
        }

    }

    function run() public {
        FundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {

    function addConsumerUsingConfig(address mostRecentlyDeployed) public {
        HelperConfig helperConfig=new HelperConfig();
        address vrfCoordinator=helperConfig.getConfig().vrfCoordinator;
        uint256 subId=helperConfig.getConfig().subscriptionId;
        addConsumer(mostRecentlyDeployed,vrfCoordinator,subId);
    }

    function addConsumer(address contractToAddToVrf,address vrfCoordinator, uint256 subId) public{
        console.log("Adding Consumer Contract:",contractToAddToVrf);
        console.log("Using VrfCoordinator Id:",vrfCoordinator);
        console.log("On Chain Id:",block.chainid);
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId,contractToAddToVrf);
        vm.stopBroadcast();
    }

    function run() public {
        address mostRecentlyDeployed=DevOpsTools.get_most_recent_deployment('Raffle',block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}