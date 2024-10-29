// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.20;

contract Timelick {
    address public owner;

    uint256 public constant MIN_DELAY = 10;
    uint256 public constant MAX_DELAY = 100;
    uint256 public constant EXPPIRY_DELAY = 1000;

    mapping(bytes32 => bool) public queuedTxs;

    event Queued(
        bytes32 indexed txId, 
        address indexed to, 
        uint256 value, 
        string func, 
        bytes data, 
        uint256 timestamp
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not an owner!");
        _;
    }

    function queue(
            address _to, 
            uint256 _value, 
            string calldata _func,
            bytes calldata _data, 
            uint256 _timestamp
        ) external onlyOwner returns(bytes32) {
            bytes32 txId = keccak256(
                abi.encode(
                    _to, _value, _func, _data, _timestamp
                )
            );
            require(!queuedTxs[txId], "already queued!");
            require(
                _timestamp >= block.timestamp + MIN_DELAY && 
                _timestamp <= block.timestamp + MAX_DELAY,
                "invalid timestamp!"
            );

            queuedTxs[txId] = true;

            emit Queued(
                txId, 
                _to, 
                _value, 
                _func, 
                _data,
                _timestamp
            );

        return txId;

    }



    
}