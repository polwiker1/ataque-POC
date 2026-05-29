// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract DelegatecallProxySafe {
    address public owner;
    address public implementation;
    uint256 public value;

    event ImplementationUpdated(address indexed oldImplementation, address indexed newImplementation);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor(address _implementation) {
        require(_implementation != address(0), "Invalid implementation");
        owner = msg.sender;
        implementation = _implementation;
    }

    // SAFE: only owner can upgrade implementation
    function setImplementation(address _implementation) external onlyOwner {
        require(_implementation != address(0), "Invalid implementation");
        address old = implementation;
        implementation = _implementation;
        emit ImplementationUpdated(old, _implementation);
    }

    // Optional owner transfer to model real admin ops
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner");
        owner = newOwner;
    }

    function executeSetValue(uint256 _value) external {
        (bool ok,) = implementation.delegatecall(
            abi.encodeWithSignature("setValue(uint256)", _value)
        );
        require(ok, "delegatecall failed");
    }
}
