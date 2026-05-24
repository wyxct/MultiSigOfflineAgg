// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../libraries/AddressUtils.sol";
import "../libraries/MathUtils.sol";

contract MultisigAgg is UUPSUpgradeable, ReentrancyGuardUpgradeable {
    
    using AddressUtils for address;
    using MathUtils for uint;

    uint private needWeight;
    mapping(address => owner) private owners;
    transaction[] private transactions;
    mapping(uint => mapping(address => bool)) private signatures;
    struct owner {
        uint weight;
        bool active;
    }

    struct transaction {
        address to;
        uint amount;
        uint weight;
        bool executed;
        bool revoked;
    }

    event SubmitTransaction(address indexed submitAddr, address to, uint amount);
    event SignTransaction(address indexed signAddr, uint indexed txIndex, uint weight);
    event ExecuteTransaction(address indexed execAddr, uint indexed txIndex);
    event RevokeTransaction(address indexed revokeAddr, uint indexed txIndex);
    
    constructor() {
        _disableInitializers();
    }

    modifier onlyOwners {
        require(owners[msg.sender].active, "Not an owner");
        _;
    }

    function Initialize(address[] memory _owners, uint[] memory _weights, uint _needWeight) public initializer {
        __ReentrancyGuard_init();
        require(_owners.length == _weights.length, "Owners and weights length mismatch");
        for (uint i = 0; i < _owners.length; i++) {
            require(!_owners[i].isZeroAddress(), "Owner cannot be zero address");
            require(_weights[i].isNonZero(), "Weight must be greater than 0");
            owners[_owners[i]] = owner(_weights[i], true);
        }
        needWeight = _needWeight;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex) public view returns (address to, uint amount, uint weight, bool executed, bool revoked) {
        transaction storage txn = transactions[_txIndex];
        return (txn.to, txn.amount, txn.weight, txn.executed, txn.revoked);
    }

    function submitTransaction(address _to, uint _amount) public onlyOwners returns (uint) {
        require(!_to.isZeroAddress(), "Recipient cannot be zero address");
        require(_amount.isNonZero(), "Amount must be greater than 0");
        transactions.push(transaction(_to, _amount, 0, false, false));
        emit SubmitTransaction(msg.sender, _to, _amount);
        return transactions.length - 1;
    }

    function signTransaction(uint _txIndex) public onlyOwners{
        transaction storage txn = transactions[_txIndex];
        require(!txn.executed, "Transaction already executed");
        require(!txn.revoked, "Transaction already revoked");
        require(!signatures[_txIndex][msg.sender], "Already signed");
        signatures[_txIndex][msg.sender] = true;
        txn.weight += owners[msg.sender].weight;
        emit SignTransaction(msg.sender, _txIndex, owners[msg.sender].weight);
    }

    function executeTransaction(uint _txIndex) public onlyOwners nonReentrant {
        transaction storage txn = transactions[_txIndex];
        require(!txn.executed, "Transaction already executed");
        require(!txn.revoked, "Transaction already revoked");
        require(txn.weight >= needWeight, "Not enough weight to execute");
        txn.executed = true;
        txn.to.safeTransferETH(txn.amount);
        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwners {}  
}
