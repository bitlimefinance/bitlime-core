pragma solidity =0.5.16;

import './interfaces/IBitlimeV2Factory.sol';
import './BitlimeV2Pair.sol';

contract BitlimeV2Factory is IBitlimeV2Factory {
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(BitlimeV2Pair).creationCode));

    uint public fee = 25;
    address public feeTo;
    address public feeToSetter;
    address public Lime;
    bool public allowAlienPools = false;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _feeToSetter, address _Lime) public {
        feeToSetter = _feeToSetter;
        Lime = _Lime;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, 'BitlimeV2: IDENTICAL_ADDRESSES');
        require(tokenA == Lime || tokenB == Lime || allowAlienPools, 'BitlimeV2: LIME_IS_NECESSARY');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'BitlimeV2: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'BitlimeV2: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(BitlimeV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IBitlimeV2Pair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'BitlimeV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    //function for set dex fees
    function setFee(uint _fee) external {
        require(msg.sender == feeToSetter, 'BitlimeV2: FORBIDDEN');
        fee = _fee;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'BitlimeV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }

    function setAlienPools(bool _allowAlienPools) external {
        require(msg.sender == feeToSetter, 'BitlimeV2: FORBIDDEN');
        allowAlienPools = _allowAlienPools;
    }
}
