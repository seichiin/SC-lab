// SPDX-License-Identifier: MIT 
pragma solidity 0.8.24;

// IERC20

// Token
// Balance - Mapping
// Name - symbol
// Allowance
// Total supply - CMC,

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SotatekStandardToken is ERC20, Ownable, AccessControl {
    address private _owner = 0xA880B1F978226288C452C3d7DFE479091Ab7F5ab;
    address private _treasury = 0xA880B1F978226288C452C3d7DFE479091Ab7F5ab;

    mapping (address => bool) private _isBlackList;

    uint private constant TAX_PERCENTAGE = 5;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(address => uint) private blacklist;

    constructor(uint256 initialSupply, address minter) ERC20("Tyson", "TSC") Ownable(_owner) {
        _mint(_owner, initialSupply);
            
        // Grant the minter role to a specified account
        _grantRole(MINTER_ROLE, minter);
    }

    function mint(address _user, uint _amount) external onlyOwner {
        require(hasRole(MINTER_ROLE, msg.sender), "Error: You have no permission to use this function.");
        require(!_isBlackList[_user], "Error: This user is in blacklist");

        (uint _tax, uint _afterTaxAmount) = getAfterTaxAmount(_amount);
        _mint(_treasury, _tax);
        _mint(_user, _afterTaxAmount);
    }

    function burn(address _user, uint _amount) external onlyOwner {
        require(!_isBlackList[_user], "Error: This user is in blacklist");

        (uint _tax, uint _afterTaxAmount) = getAfterTaxAmount(_amount);
        _mint(_treasury, _tax);
        _burn(_user, _afterTaxAmount);
    }

     function setBlacklistAccountStatus(address _account, bool status) external onlyOwner {
        _isBlackList[_account] = status;
    }

     function setTreasuryAccount(address _account) external onlyOwner {
        _treasury = _account;
    }

    function getAfterTaxAmount(uint _amount) internal pure returns(uint256, uint256) {
        uint tax = _amount * TAX_PERCENTAGE / 100;
        uint afterTaxAmount = _amount - tax;
        return (tax, afterTaxAmount);
    }
}