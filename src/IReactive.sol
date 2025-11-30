// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IReactive {
    // Structure for incoming log records from the Reactive Network
    struct LogRecord {
        uint256 chain_id;
        address _contract;
        uint256 topic_0;
        uint256 topic_1;
        uint256 topic_2;
        uint256 topic_3;
        bytes data;
        uint256 block_number;
        uint256 op_code;
        uint256 block_hash;
        uint256 tx_hash;
        uint256 log_index;
    }

    // Event emitted by the reactive contract to trigger a cross-chain transaction
    event Callback(
        uint256 indexed chain_id,
        address indexed _contract,
        uint64 indexed gas_limit,
        bytes payload
    );

    // The main function called by the Reactive Network upon a subscribed event
    function react(LogRecord calldata log) external;
}

interface ISystemContract {
    function subscribe(
        uint256 chainId,
        address _contract,
        uint256 topic0,
        uint256 topic1,
        uint256 topic2,
        uint256 topic3
    ) external payable;
}

// Placeholder for the REACTIVE_IGNORE constant
uint256 constant REACTIVE_IGNORE = 0xa65f96fc951c35ead38878e0f0b7a3c744a6f5ccc1476b313353ce31712313ad;
