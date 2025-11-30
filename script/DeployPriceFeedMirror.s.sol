// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/PriceFeedMirror.sol";

contract DeployPriceFeedMirror is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address systemContract = 0x0000000000000000000000000000000000fffFfF;
        address chainlinkAggregator = 0x001382149eBa3441043c1c66972b4772963f5D43;
        address feedProxy = 0xc9f36411C9897e7F959D99ffca2a0Ba7ee0D7bDA;
        uint256 originChainId = 80002;
        uint256 destinationChainId = 11155111;
        
        vm.startBroadcast(deployerKey);
        
        PriceFeedMirror mirror = new PriceFeedMirror(
            systemContract,
            originChainId,
            chainlinkAggregator,
            destinationChainId,
            feedProxy
        );
        
        console.log("PriceFeedMirror deployed to Reactive Lasna at:", address(mirror));
        
        vm.stopBroadcast();
    }
}