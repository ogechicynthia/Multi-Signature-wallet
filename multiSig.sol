// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 contract multisigWallet{

    address[] public owners;
    uint numConfirmationsRequired;
    uint transactionId;

    struct Transactions{
        address to;
        uint value;
        bool executed;
    }

    mapping(uint => mapping(address => bool)) public isConfirmed;
    Transactions[] public transactions;

    event transactionSubmitted(uint transactionId, address sender, address receiver, uint amount);
    event transactionConfirmed(uint _transactionId);
    event transactionExecuted(uint _transactionId);

    constructor(address[] memory _owners, uint _numComfirmationsRequired){
        require(_owners.length > 1, "Owners required must be greater than 1");
        require(_numComfirmationsRequired > 0 && _numComfirmationsRequired <= _owners.length, "Num of confirmations are not in sync with num of owners " );

        for (uint i=0; i < _owners.length; i++) {
            require(_owners[i]!=address(0), "invalid Address");
            owners.push(_owners[i]);
       }
        numConfirmationsRequired = _numComfirmationsRequired;
    }
     
    function submitTransaction(address _to) public payable {
      require(_to!=address(0), "Invalid Receiver's Address");
      require(msg.value > 0, "Transfer Amount Must be greater than 0");
            transactionId = transactions.length;
            transactions.push(Transactions({to:_to, value:msg.value, executed:false}));
      emit transactionSubmitted(transactionId, msg.sender, _to, msg.value);
    }
 
    function confirmTransaction(uint _transactionId) public {
       require(_transactionId < transactions.length, "Invalid Transaction");
       require(!isConfirmed[_transactionId][msg.sender], "Transaction alredy Approved");
       isConfirmed[_transactionId][msg.sender] = true;
       emit transactionConfirmed(_transactionId);
       if(isTransactionConfirmed(_transactionId)){
        executeTransaction(_transactionId);
       }
    }
    function executeTransaction(uint _transactionId) public payable{
      require(transactionId < transactions.length, "invalid Transaction Id");
      require(!transactions[_transactionId].executed, "Transaction is Already Executed");
       (bool success,) = transactions[_transactionId].to.call{value:transactions[_transactionId].value}("");
         require(success, "Transaction Execution failed");
         transactions[_transactionId].executed = true;
         emit transactionExecuted(_transactionId);
    }

    function isTransactionConfirmed(uint _transactionId) internal view returns(bool){
       require(transactionId < transactions.length, "invalid Transaction Id");
       uint confirmationCount;//initialy zero

       for(uint i = 0; i < owners.length; i++){
        if(isConfirmed[_transactionId][owners[i]]){
            confirmationCount++;
        }
       }
         return confirmationCount >= numConfirmationsRequired;
    }

 }   