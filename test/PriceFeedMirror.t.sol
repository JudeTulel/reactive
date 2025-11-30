// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "../src/PriceFeedMirror.sol";
import "../src/FeedProxy.sol";
import "../src/IReactive.sol";
import "../src/IAggregatorV3Interface.sol";

contract PriceFeedMirrorTest is Test {
    uint256 private constant ORIGIN_CHAIN_ID = 80001; // Polygon Mumbai
    uint256 private constant DESTINATION_CHAIN_ID = 11155111; // Ethereum Sepolia
    uint64 private constant EXPECTED_GAS_LIMIT = 1_000_000;
    uint256 private constant ANSWER_UPDATED_TOPIC = uint256(keccak256("AnswerUpdated(int256,uint256,uint256)"));
    bytes32 private constant CALLBACK_DOMAIN = keccak256("Reactive.PriceFeedMirror");
    uint16 private constant CALLBACK_VERSION = 1;
    uint8 private constant FEED_DECIMALS = 8;
    string private constant FEED_DESCRIPTION = "MATIC / USD";
    address private constant REACTIVE_VM_ID = address(0x1234);

    MockAggregator private aggregator;
    MockSystemContract private systemContract;
    FeedProxy private feedProxy;
    PriceFeedMirror private mirror;

    function setUp() public {
        vm.warp(1_000_000);
        aggregator = new MockAggregator(FEED_DECIMALS, FEED_DESCRIPTION);
        systemContract = new MockSystemContract();
        feedProxy = new FeedProxy(REACTIVE_VM_ID, address(aggregator), FEED_DECIMALS, FEED_DESCRIPTION);
        mirror = new PriceFeedMirror(
            address(systemContract),
            ORIGIN_CHAIN_ID,
            address(aggregator),
            DESTINATION_CHAIN_ID,
            address(feedProxy),
            FEED_DECIMALS,
            FEED_DESCRIPTION,
            true
        );
    }

    function testConstructorSubscribesToAnswerUpdatedTopic() public view {
        (
            uint256 chainId,
            address contractAddress,
            uint256 topic0,
            uint256 topic1,
            uint256 topic2,
            uint256 topic3
        ) = systemContract.lastSubscription();

        assertEq(chainId, ORIGIN_CHAIN_ID, "origin chain mismatch");
        assertEq(contractAddress, address(aggregator), "aggregator not subscribed");
        assertEq(topic0, ANSWER_UPDATED_TOPIC, "topic0 mismatch");
        assertEq(topic1, REACTIVE_IGNORE, "topic1 should ignore");
        assertEq(topic2, REACTIVE_IGNORE, "topic2 should ignore");
        assertEq(topic3, REACTIVE_IGNORE, "topic3 should ignore");
        assertTrue(systemContract.subscribeCalled(), "subscribe not invoked");
    }

    function testReactEmitsCallbackAndFeedProxyMirrorsData() public {
        uint80 roundId = 101_001;
        int256 answer = 1500 * 1e8;
        uint256 updatedAt = block.timestamp;
        uint256 startedAt = updatedAt; // Mirror approximates startedAt with updatedAt
        uint80 answeredInRound = roundId;

        IReactive.LogRecord memory log = IReactive.LogRecord({
            chain_id: ORIGIN_CHAIN_ID,
            _contract: address(aggregator),
            topic_0: ANSWER_UPDATED_TOPIC,
            topic_1: _encodeSigned(answer),
            topic_2: roundId,
            topic_3: 0,
            data: abi.encode(updatedAt),
            block_number: block.number,
            op_code: 0,
            block_hash: uint256(bytes32(blockhash(block.number))),
            tx_hash: 0,
            log_index: 0
        });

        bytes memory expectedPayload = abi.encodeWithSelector(
            bytes4(
                keccak256(
                    "updatePriceFeed(address,address,uint8,string,uint80,int256,uint256,uint256,uint80,bytes32,uint16)"
                )
            ),
            address(0),
            address(aggregator),
            FEED_DECIMALS,
            FEED_DESCRIPTION,
            roundId,
            answer,
            startedAt,
            updatedAt,
            answeredInRound,
            CALLBACK_DOMAIN,
            CALLBACK_VERSION
        );

    vm.expectEmit(true, true, true, true, address(mirror));
    emit IReactive.Callback(DESTINATION_CHAIN_ID, address(feedProxy), EXPECTED_GAS_LIMIT, expectedPayload);

    vm.prank(address(systemContract));
    mirror.react(log);

        vm.prank(REACTIVE_VM_ID);
        feedProxy.updatePriceFeed(
            REACTIVE_VM_ID,
            address(aggregator),
            FEED_DECIMALS,
            FEED_DESCRIPTION,
            roundId,
            answer,
            startedAt,
            updatedAt,
            answeredInRound,
            CALLBACK_DOMAIN,
            CALLBACK_VERSION
        );

        (
            uint80 storedRoundId,
            int256 storedAnswer,
            uint256 storedStartedAt,
            uint256 storedUpdatedAt,
            uint80 storedAnsweredInRound
        ) = feedProxy.latestRoundData();

        assertEq(storedRoundId, roundId, "roundId mismatch");
        assertEq(storedAnswer, answer, "answer mismatch");
        assertEq(storedStartedAt, startedAt, "startedAt mismatch");
        assertEq(storedUpdatedAt, updatedAt, "updatedAt mismatch");
        assertEq(storedAnsweredInRound, answeredInRound, "answeredInRound mismatch");
    }

    function testFeedProxyRejectsUnauthorizedVm() public {
        uint80 roundId = 7;
        int256 answer = 42 * 1e8;
        uint256 startedAt = block.timestamp - 10;
        uint256 updatedAt = block.timestamp;

        vm.expectRevert(FeedProxy.UnauthorizedVm.selector);
        feedProxy.updatePriceFeed(
            address(0xBEEF),
            address(aggregator),
            FEED_DECIMALS,
            FEED_DESCRIPTION,
            roundId,
            answer,
            startedAt,
            updatedAt,
            roundId,
            CALLBACK_DOMAIN,
            CALLBACK_VERSION
        );
    }

    function testFeedProxyRejectsMetadataMismatch() public {
        uint80 roundId = 9;
        int256 answer = 1_000 * 1e8;

        vm.expectRevert(FeedProxy.InvalidMetadata.selector);
        vm.prank(REACTIVE_VM_ID);
        feedProxy.updatePriceFeed(
            REACTIVE_VM_ID,
            address(aggregator),
            FEED_DECIMALS + 1,
            FEED_DESCRIPTION,
            roundId,
            answer,
            block.timestamp,
            block.timestamp,
            roundId,
            CALLBACK_DOMAIN,
            CALLBACK_VERSION
        );
    }
}

function _encodeSigned(int256 value) pure returns (uint256 topicValue) {
    assembly {
        topicValue := value
    }
}

contract MockAggregator is IAggregatorV3Interface {
    uint8 public immutable override decimals;
    string public override description;

    uint80 private latestRoundId;
    int256 private latestAnswer;
    uint256 private latestStartedAt;
    uint256 private latestUpdatedAt;
    uint80 private latestAnsweredInRound;

    constructor(uint8 _decimals, string memory _description) {
        decimals = _decimals;
        description = _description;
    }

    function pushRound(
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) external {
        latestRoundId = roundId;
        latestAnswer = answer;
        latestStartedAt = startedAt;
        latestUpdatedAt = updatedAt;
        latestAnsweredInRound = answeredInRound;
    }

    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (latestRoundId, latestAnswer, latestStartedAt, latestUpdatedAt, latestAnsweredInRound);
    }

    function getRoundData(uint80 _roundId)
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        require(_roundId == latestRoundId, "MockAggregator: round not found");
        return (latestRoundId, latestAnswer, latestStartedAt, latestUpdatedAt, latestAnsweredInRound);
    }

    function version() external pure override returns (uint256) {
        return 1;
    }
}

contract MockSystemContract is ISystemContract {
    struct Subscription {
        uint256 chainId;
        address contractAddress;
        uint256 topic0;
        uint256 topic1;
        uint256 topic2;
        uint256 topic3;
    }

    Subscription private _lastSubscription;
    bool private _subscribeCalled;

    event Subscribed(
        uint256 chainId,
        address contractAddress,
        uint256 topic0,
        uint256 topic1,
        uint256 topic2,
        uint256 topic3
    );

    function subscribe(
        uint256 chainId,
        address contractAddress,
        uint256 topic0,
        uint256 topic1,
        uint256 topic2,
        uint256 topic3
    ) external payable override {
        _lastSubscription = Subscription(chainId, contractAddress, topic0, topic1, topic2, topic3);
        _subscribeCalled = true;
        emit Subscribed(chainId, contractAddress, topic0, topic1, topic2, topic3);
    }

    function lastSubscription()
        external
        view
        returns (
            uint256 chainId,
            address contractAddress,
            uint256 topic0,
            uint256 topic1,
            uint256 topic2,
            uint256 topic3
        )
    {
        Subscription memory sub = _lastSubscription;
        return (sub.chainId, sub.contractAddress, sub.topic0, sub.topic1, sub.topic2, sub.topic3);
    }

    function subscribeCalled() external view returns (bool) {
        return _subscribeCalled;
    }
}