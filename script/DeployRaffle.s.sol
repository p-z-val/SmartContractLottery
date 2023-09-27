//SPDX-License-Identifier: MIT

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription,FundSubscription,AddConsumer} from "./Interactions.s.sol";

pragma solidity ^0.8.18;

contract DeployRaffle is Script{
    function run() external returns(Raffle,HelperConfig){// It is a good both Raffle & HelperConfig. That way our Tests have access to both contracts
        HelperConfig helperConfig=new HelperConfig();
        (uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        address link,
        uint256 deployerKey
        )=helperConfig.activeNetworkConfig();

        if(subscriptionId==0){
            CreateSubscription createSubscription=new CreateSubscription();
            subscriptionId=createSubscription.createSubscription(vrfCoordinator,deployerKey);
        }
        //We need to create a subscription if we don't have it. We created it in Interactions.s.sol
        //After creating subscription we need to fund it
        FundSubscription fundSubscription=new FundSubscription();
        fundSubscription.fundSubscription(vrfCoordinator,subscriptionId,link,deployerKey);

        //After funding we need to deploy it
        vm.startBroadcast();
        Raffle raffle=new Raffle(entranceFee,interval,vrfCoordinator,gasLane,subscriptionId,callbackGasLimit);
        vm.stopBroadcast();
        //After Deploying we need to add it as a consumer
        //Since its a brand new Raffle everytime we need to add a new consumer everytime
        AddConsumer addConsumer=new AddConsumer();
        addConsumer.addConsumer(address(raffle),vrfCoordinator,subscriptionId,deployerKey);


        return (raffle,helperConfig);
    }

}


// We use Helper config because a lot of the parameters we use to deploy are dependent on the chain so we use HelperConfig to have all that stored
//We need to get the subscription ID
