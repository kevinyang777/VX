//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SharkOutlawSquadVX is Ownable, EIP712, ERC721Enumerable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // Specification
    uint256 public constant TOTAL_MAX_QTY = 7777;
    uint256 public constant MAX_QTY_PER_MINTER = 1;
    uint256 public constant PUBLIC_MINT_PRICE = 0 ether;
    uint256 public PUBLIC_NOPIXEL_MINT_PRICE = 0.2 ether;

    mapping(uint256 => uint256) public tokenIdMinterToTokenQty;
    // Path to genesis and pixel smart contract
    address private _genesisSmartContract =
        0xd9145CCE52D386f254917e481eB44e9943F39138;
    address private _pixelSmartContract =
        0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8;
    Counters.Counter private _tokenIds;
    string private _contractURI;
    string private _tokenBaseURI;

    // Sales status
    bool public isSalesActivated;

    constructor()
        ERC721("Shark Outlaw Squad VX", "SHARKVX")
        EIP712("Shark Outlaw Squad VX", "1")
    {}

    function mintNFT(uint256 genesisToken, uint256 pixelToken)
        external
        payable
    {
        require(_tokenIds.current() <= TOTAL_MAX_QTY, "Exceed total max limit");
        require(isSalesActivated, "Public sale is closed");
        require(
            tokenIdMinterToTokenQty[genesisToken] + 1 <= MAX_QTY_PER_MINTER,
            "Exceed sales max quantity per Genesis NFT"
        );
        address genesisOwner = genesisCheckOwner(genesisToken);
        address pixelOwner = pixelCheckOwner(pixelToken);
        uint256 newItemId = 0;
        if (genesisOwner == msg.sender && pixelOwner == msg.sender) {
            tokenIdMinterToTokenQty[genesisToken] += 1;
            _tokenIds.increment();
            newItemId = _tokenIds.current();
            _safeMint(msg.sender, newItemId);
        } else if (genesisOwner == msg.sender && pixelOwner != msg.sender) {
            require(msg.value >= PUBLIC_NOPIXEL_MINT_PRICE, "Insufficient ETH");
            (bool success, ) = payable(msg.sender).call{
                value: PUBLIC_NOPIXEL_MINT_PRICE
            }("");
            require(success, "Ethereum Not Received");
            tokenIdMinterToTokenQty[genesisToken] += 1;
            _tokenIds.increment();
            newItemId = _tokenIds.current();
            _safeMint(msg.sender, newItemId);
        } else {
            require(false, "Not Owner");
        }
    }

    function genesisCheckOwner(uint256 _id) private returns (address) {
        (bool success, bytes memory data) = _genesisSmartContract.call(
            abi.encodeWithSignature("ownerOf(uint256)", _id)
        );
        require(success, "Owner Invalid");
        // Decode data
        address owner = abi.decode(data, (address));

        return owner;
    }

    function pixelCheckOwner(uint256 _id) private returns (address) {
        (bool success, bytes memory data) = _pixelSmartContract.call(
            abi.encodeWithSignature("ownerOf(uint256)", _id)
        );
        if (success) {
            address owner = abi.decode(data, (address));
            return owner;
        } else {
            return 0x0000000000000000000000000000000000000000;
        }
    }

    function changeNoPixelPrice(uint256 price)
        external
        onlyOwner
        returns (uint256)
    {
        PUBLIC_NOPIXEL_MINT_PRICE = price;
        return PUBLIC_NOPIXEL_MINT_PRICE;
    }

    function withdrawAll() external onlyOwner {
        require(address(this).balance > 0, "No amount to withdraw");
        payable(msg.sender).transfer(address(this).balance);
    }

    function togglePublicSalesStatus() external onlyOwner {
        isSalesActivated = !isSalesActivated;
    }

    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }

    // To support Opensea contract-level metadata
    // https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    // To support Opensea token metadata
    // https://docs.opensea.io/docs/metadata-standards
    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(_tokenId), "Token not exist");

        return string(abi.encodePacked(_tokenBaseURI, _tokenId.toString()));
    }
}
