// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {Script} from "lib/forge-std/src/Script.sol";
import {Test} from "lib/forge-std/src/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig,CodeConstants} from "../../script/HelperConfig.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Vm} from "lib/forge-std/src/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
contract RaffleTest is CodeConstants,Test{
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
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value:entranceFee}();
    }

    function testCheckUpKeepReturnsIfItHasNoBalance() public {
        //Arrange
        vm.warp(block.timestamp+interval+1);
        vm.roll(block.number+1);
        //Act
        (bool upKeepNeeded,)=raffle.checkUpkeep("");
        //assert
        assert(!upKeepNeeded);
    }

    function testCheckUpkeepReturnFalseIfRaffleIsntOpen() public{
        //Arrange 
        vm.prank(PLAYER);
        raffle.enterRaffle{value:entranceFee}();
        vm.warp(block.timestamp+interval+1);
        vm.roll(block.number+1);
        raffle.performUpkeep("");

        //Act
        (bool upKeepNeeded,)=raffle.checkUpkeep("");

        //Assert
        assert(!upKeepNeeded);
    }

    function testCheckUpKeepReturnsFalseEnoughTimehasPassed() public{
        //Arrange 
        vm.prank(PLAYER);
        raffle.enterRaffle{value:entranceFee}();

        (bool upKeepNeed,)=raffle.checkUpkeep("");

        assert(!upKeepNeed);
    }

    function testCheckUpkeepReturnsTrueWhenParametersGood() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value:entranceFee}();
        vm.warp(block.timestamp+interval+1);
        vm.roll(block.number+1);

        (bool upKeepNeed,)=raffle.checkUpkeep("");

        // assert(upKeepNeed==true);
        assert(upKeepNeed);

    }

    /*//////////////////////////////////////////////////////////////
                             PERFORMUPKEEP
    //////////////////////////////////////////////////////////////*/
    
    function testPerformUpkeepCanOnlyRunIfCheckUpKeepsTrue() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value:entranceFee}();
        vm.warp(block.timestamp+interval+1);
        vm.roll(block.number+1);

        //Act /assert
        raffle.performUpkeep("");
    }

    function testPerformUpkeepRevertsIfCheckUpkeepsFalse() public { 
        uint256 currentBalance=0;
        uint256 numPlayers=0;
        Raffle.RaffleState rState=raffle.getRaffleState();

        vm.prank(PLAYER);
        raffle.enterRaffle{value:entranceFee}();
        
        currentBalance=currentBalance+entranceFee;
        numPlayers=1;

        //Act / Assert

        vm.expectRevert(abi.encodeWithSelector(Raffle.Raffle__upKeepNotNeeded.selector,currentBalance,numPlayers,rState));
        raffle.performUpkeep("");
    }

    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value:entranceFee}();
        vm.warp(block.timestamp+interval+1);
        vm.roll(block.number+1);
        _;
    }

    function testPerformUpkeepUpdatesRaffleStateEmitsRequestId() public raffleEntered {
        //Act / Assert
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries=vm.getRecordedLogs();
        bytes32 requestId=entries[1].topics[1];

        //Assert 
        Raffle.RaffleState raffleState=raffle.getRaffleState();
        assert(uint256(requestId)>0);
        assert(uint256(raffleState)==1);
       
    }

     /*//////////////////////////////////////////////////////////////
                            FULL FILL RANDOMWORDS
    //////////////////////////////////////////////////////////////*/

    modifier skipFork(){
        if(block.chainid !=LOCAL_CHAIN_ID){
            return;
        }
        _;

    }

    function testFulFillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 requestId) public skipFork raffleEntered {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(requestId,address(raffle));
    }
    

    //Big Test

    function testFulFillRandomWordsPicksAWinnerResetsAndSendMoney() public skipFork raffleEntered {
        //Arrange
        uint256 additionalEntrants=3; // Here totally 4 players are there because we are using raffleEntered(Which means already one player is there, so that why we ahve total 4 players herer)
        uint256 startIndex=1;
        address expectedWinner=address(1);

        for(uint256 i=1;i<startIndex+additionalEntrants;i++){
            address newPlayer=address(uint160(i));
            hoax(newPlayer,1 ether);
            raffle.enterRaffle{value:entranceFee}();
        }

        uint256 startingTimeStamp=raffle.getLastTimeStamp();
        uint256 winnerStartingBalance=expectedWinner.balance;

        //Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries=vm.getRecordedLogs();
        bytes32 requestId=entries[1].topics[1];
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(uint256(requestId),address(raffle));

        //Assert 
        address recentWinner=raffle.getRecentWinner();
        Raffle.RaffleState rState=raffle.getRaffleState();
        uint256 winnerBalance=recentWinner.balance;
        uint256 endingTimeStamp=raffle.getLastTimeStamp();
        uint256 prize=entranceFee*(additionalEntrants+1);

        vm.deal(recentWinner,STARTING_PLAYER_BALANCE);

        assert(recentWinner==expectedWinner);
        assert(uint256(rState)==0);
        assert(winnerBalance==winnerStartingBalance+prize);
        assert(endingTimeStamp > startingTimeStamp);

        // vm.deal(PLAYER, STARTING_PLAYER_BALANCE);

    }
}
