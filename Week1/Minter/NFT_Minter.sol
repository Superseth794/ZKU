// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// A contract representing a Merkle Tree to which we can dynamically push data 
contract MerkleTree {
    // Only the contract's owner can push data
    address private owner;

    // Root of the underlying merkle tree
    bytes32 private root;
    // Nodes of the underlying merkle tree
    mapping(uint => mapping(uint => bytes32)) private nodes;
    // Number of leaves pushed until now
    uint private size;

    // Constructor registering the contract's owner
    constructor (address _owner) {
        owner = _owner;
    }

    // Pushes a new piece of data in the underlying merkle tree
    // The complexity of pushing data is O(log(size + 1))
    function push(bytes32 leaf) public {
        require(msg.sender == owner);

        // We register the new piece of data
        nodes[0][size] = leaf;
        uint index = size;
        uint depth = 1;

        // We update the tree's nodes affected by the data added
        while (index > 0) {
            uint newIndex;
            if (index % 2 == 0) { // The paired node necessary to compute the parent's hash is not yet available
                newIndex = index / 2;
                nodes[depth + 1][newIndex] = keccak256(abi.encodePacked(nodes[depth][index], nodes[depth][index]));
            } else { // We can compute the real parent's hash
                newIndex = (index - 1) / 2;
                nodes[depth + 1][newIndex] = keccak256(abi.encodePacked(nodes[depth][index - 1], nodes[depth][index]));
            }
            index = newIndex;
            depth++;
        }

        // We update the root
        root = nodes[depth][0];
        size++;
    }
}

// A contract that can be used to mint NFTs named ZeroKnowledgeToken and with symbol ZKT to any address
contract Minter is ERC721 {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // Counter used to give each minted NFT a unique id
    Counters.Counter private currentTokenId;

    // On-chain storage of the NFTs' URI
    mapping (uint => string) private tokensURIs;

    // Merkle Tree contract used to record the NFTs mints
    MerkleTree private tree;

    // Constructor registering the NFTs' name and symbol, and deploying the MerkleTree smart contract
    constructor() ERC721("ZeroKnowledgeToken", "ZKT") {
        tree = new MerkleTree(address(this)); // Deploy the Merkle Tree smart contract
    }

    // Mint an NFT and give its ownership to the given address
    // @param to owner of the minted NFT
    // @return the NFT unique id
    function mint(address to) public returns (uint) {
        // Updates the ids counter to prevent two NFTs from having the same id (ids start at 1)
        currentTokenId.increment();
        uint mintedId = currentTokenId.current();

        // Mint the NFT using the inherited functions from ERC721
        _safeMint(to, mintedId);
        // Stores on-chain the NFT's URI
        tokensURIs[mintedId] = _computeTokenURI(mintedId);

        // Records the minting process in the merkle tree
        tree.push(keccak256(abi.encodePacked(
            msg.sender,
            to,
            mintedId,
            tokensURIs[mintedId]
        )));

        return mintedId;
    }

    // Computes the URI of the NFT with the given id
    // @param tokenId NFT's id
    // @return the token's URI
    function _computeTokenURI(uint256 tokenId) private pure returns (string memory) {
        bytes memory dataURI = abi.encodePacked(""
            '{',
                '"name": "ZeroKnowledgeToken', tokenId.toString(), '"',
                '"description": "A token that anyone can mint :)"',
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }

    // Finds the URI of the NFT with the given id
    // @param tokenId NFT's id
    // @return the token's URI
    function tokenURI(uint tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "Invalid token Id"
        );
        return tokensURIs[tokenId];
    }
}