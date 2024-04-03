// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts@4.7.3/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
}

contract RoyalSwap is ERC20, ReentrancyGuard {
    using SafeMath for uint256;

    address private taxWallet = 0x49D870d76794de86b80B03403492E870F6CFD017;
    uint256 public taxRate = 5;
    address private immutable initialWallet;
    // Note: In a real scenario, this should be set to the actual Uniswap pair address for your token.
    address public uniswapPairAddress;

    // Sepolia Uniswap V2 Router address
    address private constant uniswapV2RouterAddress = 0x86dcd3293C53Cf8EFd7303B57beb2a3F671dDE98;
    IUniswapV2Router02 public uniswapV2Router;

    constructor() ERC20("RoyalSwap", "RYSW") {
        initialWallet = msg.sender; // Set the initial wallet
        _mint(msg.sender, 10000000 * 10 ** decimals());

        // Set the Uniswap V2 Router
        uniswapV2Router = IUniswapV2Router02(uniswapV2RouterAddress);
        
        // Set the Uniswap pair (this should be updated to your actual Uniswap pair address)
        uniswapPairAddress = address(0); // Placeholder, set your pair address here
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        uint256 taxAmount = 0;

        // Apply tax only on transfers that are to or from the Uniswap pair,
        // but excluding the case when the initial wallet is a sender
        // to avoid taxing liquidity adds.
        if ((sender == uniswapPairAddress || recipient == uniswapPairAddress) && sender != initialWallet) {
            taxAmount = amount.mul(taxRate).div(100);
            uint256 amountAfterTax = amount.sub(taxAmount);

            // Transfer the tax to the tax wallet
            super._transfer(sender, taxWallet, taxAmount);

            // Perform the transfer after tax
            amount = amountAfterTax; // Update the amount for the actual transfer
        }

        // Perform the original transfer with the possibly updated amount
        super._transfer(sender, recipient, amount);
    }

    // Allow the contract owner to update the Uniswap pair address
    function setUniswapPairAddress(address _address) external  {
        uniswapPairAddress = _address;
    }
}
