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
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
/**
 * @title A Sample Raffle Contract
 * @author Venkaiah P
 * @notice This contract is for creating simple Raflle
 * @dev implements Chaninlink VRFv2.5
 */

contract Raffle is VRFConsumerBaseV2Plus {
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__upKeepNotNeeded(uint256 balance, uint256 playerslength, uint256 raffleState);
    /** Type Declarations */
    enum RaffleState{
        OPEN, //0
        CALCULATING //1
    }
    /**State Variables */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    // @dev The Duration of lottery in seconds
    uint256 private immutable i_interval;
    //@dev we need lastTimeStamp which mean when we deploy the contract, we should take that time as start time of our lotter contract;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint256 private s_lastTimeStamp;

    address payable[] private s_palyers;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /** Events */
    event RaffleEnter(address indexed player);
    event WinnerPicked(address indexed winner);
    
    constructor(
        uint256 entrancefee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entrancefee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_keyHash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState=RaffleState.OPEN;
        // s_vrfCoordinator.requestRandomWords();
    }

    function enterRaffle() external payable {
        // require(msg.value >=i_entranceFee,Raffle__SendMoreToEnterRaffle()); this is not suggestbale due to gas efficeint
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        if(s_raffleState != RaffleState.OPEN){
            revert Raffle__RaffleNotOpen();
        }
        s_palyers.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }

    //1.Get a Random Number
    //2.Use Random Number to pick a player
    //3.Be automated call.


    //When should the winner be PickedUp?
    /**
     * @dev This is the function that the chainlink nodes will call to see
     * if the lottery is ready to have a winner pickedup
     * The Following should be true in order for upkeepNeeded to be true
     * 1.The time interval has pass between raffle runs
     * 2.The lottery is open 
     * 3.The Contract has ETH (has Players)
     * 4.Implicity, your subscription has LINK
     */

    function checkUpkeep(bytes memory /* checkData */) public view returns(bool upkeepNeeded, bytes memory /* performData */){
        bool timePassed=(block.timestamp - s_lastTimeStamp) >= i_interval;
        bool isOpen = s_raffleState==RaffleState.OPEN;
        bool hasBalance=address(this).balance > 0;
        bool hasPlayers=s_palyers.length > 0;
        upkeepNeeded = timePassed && isOpen && hasBalance && hasPlayers;
        return(upkeepNeeded,"");
    }

    //Here we are going to modify the function name from pinkWinner this to performUpkeep() 
    // from https://docs.chain.link/chainlink-automation/guides/compatible-contracts 
    function performUpkeep(bytes memory /* performData */) external {
        //Checks
        (bool upkeepNeeded,)=checkUpkeep("");
        if(!upkeepNeeded){
            revert Raffle__upKeepNotNeeded(address(this).balance,s_palyers.length,uint256(s_raffleState));
        }
        // if ((block.timestamp - s_lastTimeStamp) < i_interval) {
        //     revert();
        // }

        //Interactions (External Contracts Interactions)
        s_raffleState=RaffleState.CALCULATING;
         VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(
                // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
            )
        });
        // uint256 requestId = 
        s_vrfCoordinator.requestRandomWords(request);
    }

    
    //CEI => Checks, Effects, Interactions

    function fulfillRandomWords(uint256 /*requestId*/, uint256[] calldata randomWords) internal override {
        // Checks

        //we need only one random number bcz NUM_WORDS we declare as 1 only.
        // So from here also randomWords[0]  we should get only one index number

        //Effecte (Internal Contract State)
        uint256 indexOfWinner=randomWords[0] % s_palyers.length;
        address payable recentWinner=s_palyers[indexOfWinner];
        s_recentWinner=recentWinner;
        s_raffleState=RaffleState.OPEN;
        s_palyers=new address payable[](0);
        s_lastTimeStamp=block.timestamp;
        emit WinnerPicked(s_recentWinner);
        //Interactions (External Contract Interactions)
        (bool success,)=recentWinner.call{value:address(this).balance}("");
        if(!success){
            revert Raffle__TransferFailed();
        }
    }

    /**
     * Getter Functions
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns(RaffleState){
        return s_raffleState;
    }

    function getRequestConfirmations() external pure returns(uint16){
        return REQUEST_CONFIRMATIONS;
    }

    function getPlayer(uint256 indexPlayer) external view returns(address){
        return s_palyers[indexPlayer];
    }
}
