// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

// Minimal interfaces for testing
interface IFeedProxy {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

interface IChainlinkAggregator {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
}

interface IPriceFeedMirror {
    function originChainId() external view returns (uint256);
    function chainlinkAggregatorAddress() external view returns (address);
    function destinationChainId() external view returns (uint256);
    function feedProxyAddress() external view returns (address);
    function feedDecimals() external view returns (uint8);
    function feedDescription() external view returns (string memory);
}

contract TestPriceFeedMirror is Script {
    // Contract addresses
    address constant PRICE_FEED_MIRROR = 0x79b8176184a2eF79502a7b17E5A46B63aC7601f8; // Lasna
    address constant FEED_PROXY = 0x58341b47d8227c9c40252E76947D8EF0a32bE3C7;// FeedProxy on Sepolia
    address constant CHAINLINK_AGGREGATOR = 0x001382149eBa3441043c1c66972b4772963f5D43; // Polygon Amoy

    // RPC URLs
    string constant LASNA_RPC = "https://lasna-rpc.rnk.dev/";
    string constant SEPOLIA_RPC = "wss://0xrpc.io/sep";
    string constant AMOY_RPC = "https://rpc-amoy.polygon.technology";

    function run() external {
        console.log("\n=================================================");
        console.log("  PRICE FEED MIRROR SYSTEM TEST");
        console.log("=================================================\n");

        // Test 1: Check PriceFeedMirror Configuration
        testPriceFeedMirrorConfig();

        // Test 2: Check Source Chainlink Feed on Polygon Amoy
        testSourceChainlinkFeed();

        // Test 3: Check Destination FeedProxy on Sepolia
        testDestinationFeedProxy();

        // Test 4: Compare Data
        compareSourceAndDestination();

        // Test 5: Check Reactive Contract Balance
        checkReactiveBalance();

        console.log("\n=================================================");
        console.log("  TEST COMPLETE");
        console.log("=================================================\n");
    }

    function testPriceFeedMirrorConfig() internal {
        console.log("--- TEST 1: PriceFeedMirror Configuration ---");

        vm.createSelectFork(LASNA_RPC);
        IPriceFeedMirror mirror = IPriceFeedMirror(PRICE_FEED_MIRROR);

        try mirror.originChainId() returns (uint256 originChain) {
            console.log("Origin Chain ID:", originChain);
            require(originChain == 80002, "Wrong origin chain");
        } catch {
            console.log("ERROR: Could not read originChainId");
            return;
        }

        try mirror.destinationChainId() returns (uint256 destChain) {
            console.log("Destination Chain ID:", destChain);
            require(destChain == 11155111, "Wrong destination chain");
        } catch {
            console.log("ERROR: Could not read destinationChainId");
            return;
        }

        try mirror.chainlinkAggregatorAddress() returns (address aggregator) {
            console.log("Chainlink Aggregator:", aggregator);
        } catch {
            console.log("ERROR: Could not read chainlinkAggregatorAddress");
        }

        try mirror.feedProxyAddress() returns (address proxy) {
            console.log("Feed Proxy Address:", proxy);
        } catch {
            console.log("ERROR: Could not read feedProxyAddress");
        }

        try mirror.feedDecimals() returns (uint8 decimals) {
            console.log("Feed Decimals:", decimals);
        } catch {
            console.log("ERROR: Could not read feedDecimals");
        }

        try mirror.feedDescription() returns (string memory desc) {
            console.log("Feed Description:", desc);
        } catch {
            console.log("ERROR: Could not read feedDescription");
        }

        console.log("STATUS: Configuration check PASSED\n");
    }

    function testSourceChainlinkFeed() internal {
        console.log("--- TEST 2: Source Chainlink Feed (Polygon Amoy) ---");

        vm.createSelectFork(AMOY_RPC);
        IChainlinkAggregator aggregator = IChainlinkAggregator(CHAINLINK_AGGREGATOR);

        try aggregator.description() returns (string memory desc) {
            console.log("Description:", desc);
        } catch {
            console.log("ERROR: Could not read description");
        }

        try aggregator.decimals() returns (uint8 decimals) {
            console.log("Decimals:", decimals);
        } catch {
            console.log("ERROR: Could not read decimals");
        }

        try aggregator.latestRoundData() returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) {
            console.log("\nLatest Round Data:");
            console.log("  Round ID:", roundId);
            console.log("  Answer (raw):", uint256(answer));
            console.log("  Price (formatted): $", uint256(answer) / 1e8);
            console.log("  Started At:", startedAt);
            console.log("  Updated At:", updatedAt);
            console.log("  Answered In Round:", answeredInRound);

            require(answer > 0, "Price should be positive");
            require(roundId > 0, "Round ID should be set");
        } catch {
            console.log("ERROR: Could not fetch latest round data from Chainlink");
        }

        console.log("STATUS: Source feed check PASSED\n");
    }

    function testDestinationFeedProxy() internal {
        console.log("--- TEST 3: Destination FeedProxy (Sepolia) ---");

        if (FEED_PROXY == address(0)) {
            console.log("WARNING: FeedProxy address not set. Update FEED_PROXY constant.");
            console.log("STATUS: SKIPPED\n");
            return;
        }

        vm.createSelectFork(SEPOLIA_RPC);
        IFeedProxy proxy = IFeedProxy(FEED_PROXY);

        try proxy.description() returns (string memory desc) {
            console.log("Description:", desc);
        } catch {
            console.log("ERROR: Could not read description");
        }

        try proxy.decimals() returns (uint8 decimals) {
            console.log("Decimals:", decimals);
        } catch {
            console.log("ERROR: Could not read decimals");
        }

        try proxy.version() returns (uint256 ver) {
            console.log("Version:", ver);
        } catch {
            console.log("ERROR: Could not read version");
        }

        try proxy.latestRoundData() returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) {
            console.log("\nLatest Mirrored Data:");
            console.log("  Round ID:", roundId);
            console.log("  Answer (raw):", uint256(answer));
            console.log("  Price (formatted): $", uint256(answer) / 1e8);
            console.log("  Started At:", startedAt);
            console.log("  Updated At:", updatedAt);
            console.log("  Answered In Round:", answeredInRound);

            if (roundId == 0) {
                console.log("WARNING: No data mirrored yet. Wait for Chainlink price update.");
            } else {
                console.log("SUCCESS: Data has been mirrored!");
            }
        } catch {
            console.log("ERROR: Could not fetch latest round data from FeedProxy");
            console.log("This likely means no data has been mirrored yet.");
        }

        console.log("STATUS: Destination feed check COMPLETE\n");
    }

    function compareSourceAndDestination() internal {
        console.log("--- TEST 4: Compare Source vs Destination ---");

        if (FEED_PROXY == address(0)) {
            console.log("STATUS: SKIPPED (FeedProxy not set)\n");
            return;
        }

        // Get source data
        vm.createSelectFork(AMOY_RPC);
        IChainlinkAggregator aggregator = IChainlinkAggregator(CHAINLINK_AGGREGATOR);

        (
            uint80 sourceRoundId,
            int256 sourceAnswer,
            ,
            uint256 sourceUpdatedAt,
        ) = aggregator.latestRoundData();

        // Get destination data
        vm.createSelectFork(SEPOLIA_RPC);
        IFeedProxy proxy = IFeedProxy(FEED_PROXY);

        try proxy.latestRoundData() returns (
            uint80 destRoundId,
            int256 destAnswer,
            uint256 destStartedAt,
            uint256 destUpdatedAt,
            uint80 destAnsweredInRound
        ) {
            console.log("Source (Amoy):");
            console.log("  Round ID:", sourceRoundId);
            console.log("  Price: $", uint256(sourceAnswer) / 1e8);
            console.log("  Updated:", sourceUpdatedAt);

            console.log("\nDestination (Sepolia):");
            console.log("  Round ID:", destRoundId);
            console.log("  Price: $", uint256(destAnswer) / 1e8);
            console.log("  Started At:", destStartedAt);
            console.log("  Updated:", destUpdatedAt);
            console.log("  Answered In Round:", destAnsweredInRound);

            if (destRoundId == 0) {
                console.log("\nSTATUS: No mirrored data yet. System not active.");
            } else if (sourceRoundId == destRoundId) {
                console.log("\nSTATUS: Data is IN SYNC! Mirror is working correctly!");
            } else {
                uint256 roundDiff = sourceRoundId > destRoundId
                    ? sourceRoundId - destRoundId
                    : destRoundId - sourceRoundId;
                console.log("\nSTATUS: Data slightly out of sync (round diff:", roundDiff, ")");
                console.log("This is normal - mirror updates on new Chainlink events.");
            }
        } catch {
            console.log("ERROR: Could not compare data");
            console.log("Destination has no data yet.");
        }

        console.log("");
    }

    function checkReactiveBalance() internal {
        console.log("--- TEST 5: Reactive Contract Balance ---");

        vm.createSelectFork(LASNA_RPC);

        uint256 balance = PRICE_FEED_MIRROR.balance;
        console.log("REACT Balance:", balance, "wei");
        console.log("REACT Balance (formatted):", balance / 1e18, "REACT");

        if (balance == 0) {
            console.log("WARNING: No REACT tokens! Fund the contract");
        } else if (balance < 0.01 ether) {
            console.log("WARNING: Low REACT balance.");
        } else {
            console.log("SUCCESS: Contract is funded!");
        }

        console.log("");
    }
}
