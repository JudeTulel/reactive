// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAggregatorV3Interface.sol";

/**
 * @title FeedProxy
 * @notice A minimal contract on the Destination Chain to store mirrored price data
 *         and expose an AggregatorV3Interface-compatible read interface.
 */
contract FeedProxy is IAggregatorV3Interface {
    // --- Errors ---
    error UnauthorizedVm();
    error UnexpectedFeedId();
    error InvalidDomain();
    error InvalidMetadata();

    // --- State Variables ---
    struct RoundData {
        uint80 roundId;
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }

    RoundData private latestData;
    address private immutable reactiveVmId; // The RVM ID of the authorized PriceFeedMirror contract
    address public immutable feedId;        // Canonical Chainlink feed on origin chain

    // AggregatorV3Interface required data
    uint8 public immutable decimals;
    string public description;
    bytes32 private immutable descriptionHash;

    bytes32 public constant EXPECTED_DOMAIN = keccak256("Reactive.PriceFeedMirror");
    uint16 public constant DOMAIN_VERSION = 1;

    // --- Constructor ---
    constructor(
        address _reactiveVmId,
        address _feedId,
        uint8 _decimals,
        string memory _description
    ) {
        reactiveVmId = _reactiveVmId;
        feedId = _feedId;
        decimals = _decimals;
        description = _description;
        descriptionHash = keccak256(bytes(_description));
    }

    // --- External Update Function (Called by Reactive Network) ---

    /**
     * @notice Updates the latest price feed data.
     * @dev This function is called by the Reactive Network's cross-chain transaction.
     *      The first argument is automatically replaced with the RVM ID of the caller.
     * @param _rvmId The RVM ID of the calling Reactive Contract (for authorization).
     * @param _roundId The round ID from the origin chain.
     * @param _answer The price answer from the origin chain.
     * @param _updatedAt The timestamp of the update from the origin chain.
     */
    function updatePriceFeed(
        address _rvmId,
        address _feedId,
        uint8 _decimals,
        string calldata _description,
        uint80 _roundId,
        int256 _answer,
        uint256 _startedAt,
        uint256 _updatedAt,
        uint80 _answeredInRound,
        bytes32 _domainSeparator,
        uint16 _domainVersion
    ) external {
        if (_rvmId != reactiveVmId) revert UnauthorizedVm();
        if (_feedId != feedId) revert UnexpectedFeedId();
        if (_domainSeparator != EXPECTED_DOMAIN || _domainVersion != DOMAIN_VERSION) revert InvalidDomain();
        if (_decimals != decimals || keccak256(bytes(_description)) != descriptionHash) revert InvalidMetadata();

        latestData = RoundData({
            roundId: _roundId,
            answer: _answer,
            startedAt: _startedAt,
            updatedAt: _updatedAt,
            answeredInRound: _answeredInRound
        });
    }

    // --- AggregatorV3Interface Implementation ---

    function latestRoundData()
        public
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
        // The Chainlink AggregatorV3Interface returns 5 values.
        // We only mirror roundId, answer, and updatedAt.
        // startedAt and answeredInRound are set to 0 and roundId respectively for compatibility.
        return (
            latestData.roundId,
            latestData.answer,
            latestData.startedAt,
            latestData.updatedAt,
            latestData.answeredInRound
        );
    }

    function getRoundData(uint80 _roundId)
        public
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
        require(_roundId == latestData.roundId, "FeedProxy: Round not found");

        return latestRoundData();
    }

    function version() public pure override returns (uint256) {
        return 1; // Simple version number
    }
}
