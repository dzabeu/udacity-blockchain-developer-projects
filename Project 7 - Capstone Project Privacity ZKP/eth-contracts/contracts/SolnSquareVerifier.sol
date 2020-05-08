pragma solidity >=0.4.21 <0.6.0;
import "./Verifier.sol";
import "./ERC721Mintable.sol";

// TODO define a contract call to the zokrates generated solidity contract <Verifier> or <renamedVerifier>
contract SquareVerifier is Verifier {

}

// TODO define another contract named SolnSquareVerifier that inherits from your ERC721Mintable class

contract SolnSquareVerifier is OpenSeaToken721 {

    SquareVerifier public verifier;
    
    // TODO define a solutions struct that can hold an index & an address
    struct Solution {
        uint256 solutionIndex;
        address solutionAddrsse;
    }

    // TODO define an array of the above struct
    Solution[] private solutionsArray;

    // TODO define a mapping to store unique solutions submitted
    mapping (bytes32 => address) private uniqueSolutionMapping;

    // TODO Create an event to emit when a solution is added
    event SolutionAdded(uint256 solutionIndex, address solutionAddrsse);

    constructor(address verifierAddress, string memory name, string memory symbol) OpenSeaToken721(name, symbol) public
    {
        verifier = SquareVerifier(verifierAddress);
    }

    // TODO Create a function to add the solutions to the array and emit the event
    function addSolution(uint256 index, address addr, bytes32 key) public {
        require(uniqueSolutionMapping[key] == address(0), 'Solution has been used before');
        Solution memory solution = Solution ({
                                                solutionIndex: index,
                                                solutionAddrsse: addr
                                            });

        solutionsArray.push(solution);
        uniqueSolutionMapping[key] = addr;
        emit SolutionAdded(index, addr);


    }

    // TODO Create a function to mint new NFT only after the solution has been verified
    //  - make sure the solution is unique (has not been used before)
    //  - make sure you handle metadata as well as tokenSuplly
    function mintNewToken(address to, uint256 tokenId, uint[2] memory a, uint[2][2] memory b, uint[2] memory c, uint[2] memory inputs) public {
        
        // GenerateKey from solution inputs
        bytes32 key = generateKey(a, b, c, inputs);
        require(verifier.verifyTx(a, b, c, inputs), 'Solution is not correct');
        addSolution(tokenId, to, key);
        super.mint(to, tokenId);

    }

    function generateKey(uint[2] memory a, uint[2][2] memory b, uint[2] memory c, uint[2] memory inputs)  public pure returns(bytes32) {
        return keccak256(abi.encodePacked(a, b, c, inputs));
    }

}
