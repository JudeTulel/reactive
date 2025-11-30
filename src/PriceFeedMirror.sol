// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IReactive.sol";

/**
 * @title PriceFeedMirror
 * @notice A Reactive Contract that subscribes to a Chainlink Aggregator's AnswerUpdated event
 *         and mirrors the price data to a FeedProxy contract on a destination chain.
 */
contract PriceFeedMirror is IReactive {
    // --- State Variables ---
    uint256 public immutable originChainId;
    address public immutable chainlinkAggregatorAddress;
    uint256 public immutable destinationChainId;
    address public immutable feedProxyAddress;
    ISystemContract public immutable service;
    
    // Feed metadata (hardcoded)
    uint8 public constant feedDecimals = 8; // MATIC/USD uses 8 decimals
    string public constant feedDescription = "MATIC / USD";

    // Constants
    uint64 private constant GAS_LIMIT = 1_000_000;
    uint256 private constant ANSWER_UPDATED_TOPIC = uint256(keccak256("AnswerUpdated(int256,uint256,uint256)"));
    bytes32 private constant CALLBACK_DOMAIN = keccak256("Reactive.PriceFeedMirror");
    uint16 private constant CALLBACK_VERSION = 1;
    bytes4 private constant UPDATE_SELECTOR = bytes4(keccak256(
        "updatePriceFeed(address,address,uint8,string,uint80,int256,uint256,uint256,uint80,bytes32,uint16)"
    ));

    // --- Events ---
    event Funded(address indexed funder, uint256 amount);

    // --- Modifier ---
    modifier onlyService() {
        require(msg.sender == address(service), "Pricer: caller not service");
        _;
    }

    // --- Constructor ---
    constructor(
        address _systemContract,
        uint256 _originChainId,
        address _chainlinkAggregatorAddress,
        uint256 _destinationChainId,
        address _feedProxyAddress
    ) payable {
        service = ISystemContract(payable(_systemContract));
        originChainId = _originChainId;
        chainlinkAggregatorAddress = _chainlinkAggregatorAddress;
        destinationChainId = _destinationChainId;
        feedProxyAddress = _feedProxyAddress;

        // Attempt subscription to Chainlink's AnswerUpdated event on the origin chain.
        // Reactive dev deployments (without the system contract) may revert, so swallow failures.
        try service.subscribe(
            originChainId,
            chainlinkAggregatorAddress,
            ANSWER_UPDATED_TOPIC,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE
        ) {
            // Subscription succeeded in a live Reactive environment.
        } catch {
            // No-op: local/test deployments lack the Reactive system contract.
        }
    }

    // --- IReactive Implementation ---

    /**
     * @notice The main logic function called by the Reactive Network upon a subscribed event.
     * @param log The LogRecord containing the event data from the Origin Chain.
     */
    function react(LogRecord calldata log) external onlyService {
        // 1. Security Check: Ensure the log is from the expected Chainlink Aggregator
        require(log.chain_id == originChainId, "Pricer: Unexpected chain");
        require(log._contract == chainlinkAggregatorAddress, "Pricer: Unexpected contract");
        require(log.topic_0 == ANSWER_UPDATED_TOPIC, "Pricer: Unexpected topic");

        // 2. Decode the AnswerUpdated event payload directly from the log record
        int256 answer = _toSigned(log.topic_1);
        uint80 roundId = uint80(log.topic_2);
        uint256 updatedAt = abi.decode(log.data, (uint256));

        // We do not receive startedAt or answeredInRound via the event; approximate them.
        uint256 startedAt = updatedAt;
        uint80 answeredInRound = roundId;

        // 3. Encode Callback Payload
        bytes memory payload = abi.encodeWithSelector(
            UPDATE_SELECTOR,
            address(0), // Placeholder for RVM ID (replaced by RN)
            chainlinkAggregatorAddress,
            feedDecimals,
            feedDescription,
            roundId,
            answer,
            startedAt,
            updatedAt,
            answeredInRound,
            CALLBACK_DOMAIN,
            CALLBACK_VERSION
        );

        // 4. Emit Callback to trigger cross-chain transaction
        emit Callback(
            destinationChainId,
            feedProxyAddress,
            GAS_LIMIT,
            payload
        );
    }

    receive() external payable {
        emit Funded(msg.sender, msg.value);
    }

    function _toSigned(uint256 value) private pure returns (int256 signed) {
        assembly {
            signed := value
        }
    }
}