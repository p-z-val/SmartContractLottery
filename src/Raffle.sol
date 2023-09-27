//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
//import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

/**
 * @title Smart Contract Lottery
 * @author Pramit
 * @notice This contract is a simple Raffle contract
 * @dev Implements Chainlink VRF for random number generation
 */

contract Raffle is VRFConsumerBaseV2 {
    error Raffle__UpkeepNotNeeded(
        uint256 currentBalance,
        uint256 numPlayers,
        uint256 raffleState
    );
    error Raffle__NotEnoughEthSent(); // Remember to preceed the error with the name of the contract
    error Raffle__TransferFailed();
    error Raffle__NotOpen();
    /** Type declarations */
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /** State Variables */
    address private s_recentWinner;
    RaffleState private s_raffleState; // This is the state of the lottery
    uint256 private s_lastTimeStamp; // When the lottery was last run
    address payable[] private s_players;

    uint256 private immutable i_entranceFee; // We might want to be able to change the entrance fee not keeping it contant or immutable
    //Need a data structure to keep track of all the users that enter the lottery
    uint32 private constant NUM_WORDS = 1;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint256 private immutable i_interval; // How long the lottery will run for
    bytes32 private immutable i_GasLane; // This is the keyhash
    uint64 private immutable i_subscriptionId; // This is the subscription id
    uint32 private immutable i_callbackGasLimit; // This is the callback gas limit
    uint16 private constant REQUEST_CONFIRMATIONS = 3; // How many confirmations we want

    //Duration of Lottery in seconds

    /**Events */
    event EnteredRaffle(address indexed player);
    event WinnerPicked(address indexed winner);
    event ExpectedRaffleWinner(uint256 indexed requestID);

    constructor(
        uint256 _entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = _entranceFee;
        i_interval = interval;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_GasLane = gasLane;
        s_lastTimeStamp = block.timestamp; // when we launched the contract
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() public payable {
        //require(msg.value >=i_entranceFee, "Not enough ETH to enter the raffle");
        if (msg.value < i_entranceFee) {
            //this is more gas efficient than using require
            revert Raffle__NotEnoughEthSent();
        }
        if (s_raffleState == RaffleState.CALCULATING) {
            revert Raffle__NotOpen();
        }
        s_players.push(payable(msg.sender));

        emit EnteredRaffle(msg.sender);
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. Implicity, your subscription is funded with LINK.
     */
    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        //override
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool isOpen = RaffleState.OPEN == s_raffleState;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayers = s_players.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "0x0"); // can we comment this out?
    }

    // 1.Get a Random Number
    //2.Use the Random Number to pick a player
    //3. Be automatically called
    //This is the function where we pick the Raffle Winner
    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId =  i_vrfCoordinator.requestRandomWords(
            i_GasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        emit ExpectedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal
    override
     {
        uint256 indexOfWinner = _randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0); // We don't want the previous raffles entrants to to enter the next raffle for free
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = winner.call{value: address(this).balance}("");

        if (!success) {
            //handle failure
            revert Raffle__TransferFailed();
        }

        emit WinnerPicked(winner);
    }



    /* Getter function for  Entrance Fee */
    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getNumberOfPlayers() public view returns (uint256) {
        return s_players.length;
    }
}

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
// internal & private view & pure functions
// external & public view & pure functions
