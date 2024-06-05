// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract LivingTheDream is ERC20, ERC20Burnable, Ownable, ReentrancyGuard, Pausable {
    uint256 public constant MAX_SUPPLY = 333333333333 * 10**18; 
    uint256 public constant INITIAL_SUPPLY = 33333333333 * 10**18;
    uint256 public constant MARKETING_WALLET_AMOUNT = 5533333333 * 10**18;
    uint256 public constant AIRDROP_WALLET_AMOUNT = 27777777777 * 10**18;

    mapping(address => bool) public isWhitelisted;
    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) public isExcludedFromTax;

     struct Taxes {
        uint256 buyTax;
        uint256 sellTax;
    }

    Taxes public currentTaxes;

    event TaxesChanged(uint256 buyTax, uint256 sellTax);
    

    address payable public treasuryAddress;

      constructor(address payable _treasuryAddress, address newOwner) ERC20("Living The Dream", "LTD") Ownable(msg.sender) {
        
        _mint(msg.sender, INITIAL_SUPPLY);
        _mint(0x3E55eFc604A3E021069AA4852AB5A97798301Fd5, MARKETING_WALLET_AMOUNT); // Marketing and Treasury Wallets must be configured before deploymento
        _mint(0x54412E0892c534c89A076252e3824F1f7f549c52, AIRDROP_WALLET_AMOUNT);
        currentTaxes = Taxes(7, 10);
        treasuryAddress = _treasuryAddress;
        _mint(newOwner, INITIAL_SUPPLY); // Coin the initial supply to the new owner
        transferOwnership(newOwner); //For deployment security, ownership is transferred when everything is deployed.
            
    }

    
    
  // ... (function for owner only)

    function mint(address user, uint256 amount) external onlyOwner {
        _mint(user, amount);
    }

    // Transfers are paused, but only the owner can do //
    function pause() external onlyOwner {
        _pause();
    }

    // only the owner can unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }
    
    // Burn function with onlyOwner modifier
    function burn(address account, uint256 amount) public onlyOwner { // Agregar un argumento para la dirección
        _burn(account, amount); // Quemar desde la dirección especificada
    }

    // White and black list functions
    function addToWhitelist(address account) external onlyOwner {
        isWhitelisted[account] = true;
    }

    function removeFromWhitelist(address account) external onlyOwner {
        isWhitelisted[account] = false;
    }

    function addToBlacklist(address account) external onlyOwner {
        isBlacklisted[account] = true;
    }

    function removeFromBlacklist(address account) external onlyOwner {
        isBlacklisted[account] = false;
    }

    // Función para excluir direcciones de impuestos
    function excludeFromTax(address account) external onlyOwner {
        isExcludedFromTax[account] = true;
    }

    function includeInTax(address account) external onlyOwner {
        isExcludedFromTax[account] = false;
    }

        function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual { 
        uint256 taxAmount = 0;
        if (!isExcludedFromTax[from] && !isExcludedFromTax[to]) {
            if (from == address(this)) { // Sell
                taxAmount = (amount * currentTaxes.sellTax) / 100;
            } else if (!isWhitelisted[from]) { //Purchase (and it is not on the whitelist)
                taxAmount = (amount * currentTaxes.buyTax) / 100;
            }
        }

        if (taxAmount > 0) {
            _transfer(from, treasuryAddress, taxAmount); // Transfer taxes to the treasury
        }
    }
    // Function to change treasury address (owner only)
    function setTreasuryAddress(address payable newTreasuryAddress) external onlyOwner {
        treasuryAddress = newTreasuryAddress;
    }

    function adjustTaxes(uint256 newBuyTax, uint256 newSellTax) external onlyOwner {
        require(newBuyTax <= 100, "Buy tax cannot exceed 100%");
        require(newSellTax <= 100, "Sell tax cannot exceed 100%");
        currentTaxes.buyTax = newBuyTax;
        currentTaxes.sellTax = newSellTax;
        emit TaxesChanged(newBuyTax, newSellTax);
    }

    function approveForDEX(address dexAddress, uint256 amount) external onlyOwner {
        _approve(address(this), dexAddress, amount);
    }
}

