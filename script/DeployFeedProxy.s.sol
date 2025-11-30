// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/FeedProxy.sol";

contract DeployFeedProxy is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY"); // Sepolia deployer key
        address reactiveVmId = 0xaffd76b978b9F48F3EEbEB20cB1B43C699855Ee3; // Deployed Reactive price mirrror                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         eployed PriceFeedMirror address on Reactive Lasna
        address originFeedId = 0x001382149eBa3441043c1c66972b4772963f5D43; // Chainlink MATIC/USD (POL/USD) on Polygon Amoy
        uint8 feedDecimals = 8; // MATIC/USD uses 8 decimals
        string memory feedDescription = "MATIC / USD"; // Feed description
        
        vm.startBroadcast(deployerKey);
        
        FeedProxy proxy = new FeedProxy(
            reactiveVmId,
            originFeedId,
            feedDecimals,
            feedDescription
        );
        
        console.log("FeedProxy deployed to Sepolia at:", address(proxy));
        
        vm.stopBroadcast();
    }
}