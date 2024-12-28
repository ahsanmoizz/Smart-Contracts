pragma solidity ^0.8.20;

contract Minting {
    address public immutable tokenOwner; 
    mapping(address => bool) public approved;   
    mapping(address => uint) public balance;

    event Approved(address indexed approvedAddress);
    event Minted(address indexed to, uint amount);
    event Transferred(address indexed from, address indexed to, uint amount);
    event Burned(address indexed burner, uint amount);

    constructor() {
        tokenOwner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == tokenOwner, "Only owner can perform this action");
        _;
    }

    modifier onlyApproved() {
        require(approved[msg.sender] == true, "Address is not approved");
        _;
    }

    modifier addressCheck(address to) {
        require(to != address(0), "Invalid Address");
        _;
    }

    // Approve an address
    function approve(address to) public onlyOwner addressCheck(to) {
        approved[to] = true;
        emit Approved(to);
    }

    // Mint tokens to a specific address
    function mint(address to, uint amount) public onlyOwner addressCheck(to) {
        require(amount > 0, "Invalid amount");
        balance[to] += amount;
        emit Minted(to, amount);
    }

    // Transfer tokens
    function transfer(address to, uint amount) public onlyApproved addressCheck(to) {
        require(balance[msg.sender] >= amount, "Insufficient balance");
        balance[msg.sender] -= amount;
        balance[to] += amount;
        emit Transferred(msg.sender, to, amount);
    }

    // Burn tokens
    function burn(uint amount) public onlyOwner {
        require(balance[msg.sender] >= amount, "Insufficient balance");
        balance[msg.sender] -= amount;
        emit Burned(msg.sender, amount);
    }

    // Check if an address is approved
    function checkApproved(address to) public view addressCheck(to) returns (bool) {
        return approved[to];
    }
}
