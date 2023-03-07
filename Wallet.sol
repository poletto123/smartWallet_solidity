//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

contract Wallet {
    address public owner;
    mapping(address => uint) public balance;

    address[] public guardianAddresses;
    mapping(address => mapping(address => bool)) public newOwnerApprovals;
    uint constant minimumApprovals = 3;

    mapping(address => bool) public giftAddresses;
    uint amountGift = 10;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyGuardian() {
        bool isGuardianAddress = isGuardian(msg.sender);
        require(isGuardianAddress, "Only guardians can call this function");
        _;
    }

    function isGuardian(address guardianAddress) private view returns(bool) {
        bool isGuardianAddress;
        for (uint i = 0; i < guardianAddresses.length; i++) {
            if(guardianAddresses[i] == guardianAddress) {
                isGuardianAddress = true;
            }
        }
        return isGuardianAddress;

    }

    function deposit() public payable onlyOwner {
        require(msg.value > 0, "The amount must be greater than 0");
        assert(payable(address(this)).balance > address(this).balance - msg.value);
    }

    receive() external payable {
        deposit();
    }

    function sendFunds(address payable sendAddress, uint amount, bytes memory payload) public onlyOwner returns(bytes memory){
        require(amount > 0, "The amount must be greater than 0");
        (bool success, bytes memory returnData) = sendAddress.call{value: amount}(payload);
        require(success);
        assert(address(this).balance < address(this).balance + amount);
        return(returnData);
    }

    function addAllowanceAddress(address allowanceAddress) public onlyOwner {
        require(giftAddresses[allowanceAddress] == false, "Allowance address already added");
        giftAddresses[allowanceAddress] = true;
    }

    function getGift(address payable receiverAddress) public {
        require(giftAddresses[receiverAddress] == true, "This address is not registered for gifts, or has retrieved its gift already");
        require(address(this).balance >= 10, "Not enough funds in contract");
        assert(address(this).balance < address(this).balance + amountGift);
        giftAddresses[receiverAddress] = false;
        receiverAddress.transfer(amountGift);
    }

    function addGuardian(address guardianAddress) public onlyOwner {
        bool isGuardianAddress = isGuardian(guardianAddress);
        require(!isGuardianAddress, "Guardian address already added");
        guardianAddresses.push(guardianAddress);
        assert(guardianAddresses.length > guardianAddresses.length - 1);
    }

    function approveNewOwner(address newOwnerAddress) public onlyGuardian() {
        require(newOwnerApprovals[msg.sender][newOwnerAddress] == false, "New Owner already approved the provided address");
        newOwnerApprovals[msg.sender][newOwnerAddress] = true;
    }

    function establishNewOwner(address newOwnerAddress) public onlyGuardian() {
        uint numberApprovals;
        for(uint i = 0; i < guardianAddresses.length; i++) {
            if (newOwnerApprovals[guardianAddresses[i]][newOwnerAddress] == true) {
                numberApprovals++;
            }
        }

        require(numberApprovals >= minimumApprovals, "The minimum amount of approvals was not met yet");
        owner = newOwnerAddress;
    }


}