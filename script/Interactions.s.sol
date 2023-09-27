// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {Raffle} from "../src/Raffle.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol"; 
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract CreateSubscription is Script {

    function createSubscriptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();

        (,,address vrfCoordinator,,/*uint64 subID*/,,/*address link*/,uint256 deployerKey)=helperConfig.activeNetworkConfig();
        return createSubscription(vrfCoordinator,deployerKey); 

    }

    
    function createSubscription(address vrfCoordinator,uint256 deployerKey) public returns(uint64){
        console.log("Creating Subscription on ChainID:",block.chainid);
        vm.startBroadcast(deployerKey);
        uint64 subID=VRFCoordinatorV2Mock(vrfCoordinator).createSubscription();
        console.log("Subscription ID:",subID);
        console.log("Update Subscription ID on Helper config");
        vm.stopBroadcast();
        return subID;
    }

    function run() external returns (uint64) {

        return createSubscriptionUsingConfig();
    }

}

contract FundSubscription is Script{
    uint96 public constant FUND_AMOUNT=3 ether;

    function fundSubscriptionUsingConfig() public{
        HelperConfig helperConfig=new HelperConfig();
        (,,address vrfCoordinator,,uint64 subID,,address link,uint256 deployerKey)=helperConfig.activeNetworkConfig();
        fundSubscription(vrfCoordinator,subID,link,deployerKey);
    }

    function fundSubscription(address vrfCoordinator,uint64 subID,address link,uint256 deployerKey) public{
        console.log("Funding Subscription",subID);
        console.log("Using VRF Coordinator",vrfCoordinator);
        console.log("On ChainID:",block.chainid);
        //console.log("Using Link Token",link);
        if(block.chainid==31337){
            vm.startBroadcast(deployerKey);
            VRFCoordinatorV2Mock(vrfCoordinator).fundSubscription(subID,FUND_AMOUNT);
            vm.stopBroadcast();

        }
        else{
            console.log(LinkToken(link).balanceOf(msg.sender));
            console.log(msg.sender);
            console.log(LinkToken(link).balanceOf(address(this)));
            console.log(address(this));
            vm.startBroadcast(deployerKey);
            LinkToken(link).transferAndCall(vrfCoordinator,FUND_AMOUNT,abi.encode(subID));
            vm.stopBroadcast();
        }
    }

    function run() external {
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script{
    function run() external{
        address raffle = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(raffle);
        
    }

    function addConsumerUsingConfig(address raffle) public{
        HelperConfig helperConfig=new HelperConfig();
        (,,address vrfCoordinator,,uint64 subID,,,uint256 deployerKey)=helperConfig.activeNetworkConfig();
        addConsumer(raffle,vrfCoordinator,subID,deployerKey);
    }
    function addConsumer(address raffle,address vrfCoordinator,uint64 subID,uint256 deployerKey) public{
        console.log("Adding Consumer to Raffle",raffle);
        console.log("Using VRF Coordinator",vrfCoordinator);
        console.log("On ChainID:",block.chainid);
        vm.startBroadcast(deployerKey);
        VRFCoordinatorV2Mock(vrfCoordinator).addConsumer(subID,raffle);
        vm.stopBroadcast();
    }
}