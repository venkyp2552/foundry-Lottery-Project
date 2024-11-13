// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {Script} from "lib/forge-std/src/Script.sol";
import {Test} from "lib/forge-std/src/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Raffle} from "../../src/Raffle.sol";

contract RaffleTest is Test{
    HelperConfig public helpConfig;
    Raffle public raffle;
    address public PLAYER=makeAddr('player');
    uint256 public constant STARTING_PLAYER_BALANCE=10 ether;

    event RaffleEnter(address indexed player);
    event WinnerPicked(address indexed winner);

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;

    function setUp() external{
        DeployRaffle deployer=new DeployRaffle();
        (raffle,helpConfig)=deployer.deployContract();
        HelperConfig.NetworkConfig memory config=helpConfig.getConfig();
        entranceFee=config.entranceFee;
        interval=config.interval;
        vrfCoordinator=config.vrfCoordinator;
        gasLane=config.gasLane;
        subscriptionId=config.subscriptionId;
        callbackGasLimit=config.callbackGasLimit;

        // PLAYER with Sarting Balance;
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    function testRaffleInitilizeStatusOpen() public view{
        assert(raffle.getRaffleState()==Raffle.RaffleState.OPEN);
    }

    function testRaffleConfirmatationCount() public view{
        assert(raffle.getRequestConfirmations()==3);
    }

    function testRaffleRevertsWhenYouDontPayEnough() public{
        //Arrange
        vm.prank(PLAYER);
        //Act
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        //Assert
        raffle.enterRaffle();
    }

    function testRaffleRecordsWhenPlayersEnter() public{
        //Arrange
        vm.prank(PLAYER);
        //Act 
        raffle.enterRaffle{value:entranceFee}();
        //assert
        address playerRecord=raffle.getPlayer(0);
        assert(playerRecord==PLAYER);
    }

    function testEnteringRaffleEmitsEvent() public {
        //Arrange
        vm.prank(PLAYER);
        //Act
        vm.expectEmit(true, false, false,false, address(raffle));
        emit RaffleEnter(PLAYER);
        //Assert
        raffle.enterRaffle{value:entranceFee}();
    }

    function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value:entranceFee}();
        vm.warp(block.timestamp+interval+1);
        vm.roll(block.number+1);
        raffle.performUpkeep("");

        //Act/ Assert
        vm.expectRevert();
        vm.prank(PLAYER);
        raffle.enterRaffle{value:entranceFee}();


    }

}
