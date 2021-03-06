pragma solidity ^0.4.24;

import "@aragon/os/contracts/apps/AragonApp.sol";
import "@aragon/apps-agent/contracts/Agent.sol";

import "./ICycleManager.sol";

contract Airdrop is AragonApp {

    struct Airdrop {
      bytes32 root;
      string dataURI;
      mapping(address => bool) awarded;
    }

    /// Events
    event Start(uint256 id);
    event Award(uint256 id, address recipient, uint256 amount);

    /// State
    Agent public agent;
    ICycleManager public cycleManager;
    address public sctAddress;

    mapping(uint256 => Airdrop) public airdrops;
    uint256 public airdropsCount;
    uint256 public lastRewardCycle;

    /// ACL
    bytes32 constant public START_ROLE = keccak256("START_ROLE");

    // Errors
    string private constant ERROR_AWARDED = "AWARDED";
    string private constant ERROR_INVALID = "INVALID";
    string private constant ERROR_CYCLE_NOT_ENDED = "CYCLE_NOT_ENDED";

    function initialize(Agent _agent, ICycleManager _cycleManager, address _sctAddress, bytes32 _root, string _dataURI) onlyInit public {
        initialized();

        agent = _agent;
        cycleManager = _cycleManager;
        sctAddress = _sctAddress;

        if (_root != bytes32(0) && bytes(_dataURI).length != 0) {
            _start(_root, _dataURI);
        }
    }

    /**
     * @notice Start a new airdrop `_root` / `_dataURI`
     * @param _root New airdrop merkle root
     * @param _dataURI Data URI for airdrop data
     */
    function start(bytes32 _root, string _dataURI) auth(START_ROLE) public {
        _start(_root, _dataURI);
    }

    function _start(bytes32 _root, string _dataURI) internal returns(uint256 id) {
        require(cycleManager.currentCycle() > lastRewardCycle, ERROR_CYCLE_NOT_ENDED);
        lastRewardCycle = cycleManager.currentCycle();

        id = ++airdropsCount;    // start at 1
        airdrops[id] = Airdrop(_root, _dataURI);
        emit Start(id);
    }

    /**
     * @notice Claim single award
     * @param _id Airdrop id
     * @param _recipient Recepient of award
     * @param _amount The token amount
     * @param _proof Merkle proof to correspond to data supplied
     */
    function award(uint256 _id, address _recipient, uint256 _amount, bytes32[] _proof) public {
        Airdrop storage airdrop = airdrops[_id];

        bytes32 hash = keccak256(abi.encodePacked(_recipient, _amount));
        require( validate(airdrop.root, _proof, hash), ERROR_INVALID );

        require( !airdrops[_id].awarded[_recipient], ERROR_AWARDED );

        airdrops[_id].awarded[_recipient] = true;

        agent.transfer(sctAddress, _recipient, _amount);

        emit Award(_id, _recipient, _amount);
    }

    /**
     * @notice Claim multiple awards
     * @param _ids Airdrop ids
     * @param _recipient Recepient of award
     * @param _amounts The token amounts
     * @param _proofs Merkle proofs
     * @param _proofLengths Merkle proof lengths
     */
    function awardFromMany(uint256[] _ids, address _recipient, uint256[] _amounts, bytes _proofs, uint256[] _proofLengths) public {

        uint256 totalAmount;

        uint256 marker = 32;

        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];

            bytes32[] memory proof = extractProof(_proofs, marker, _proofLengths[i]);
            marker += _proofLengths[i]*32;

            bytes32 hash = keccak256(abi.encodePacked(_recipient, _amounts[i]));
            require( validate(airdrops[id].root, proof, hash), ERROR_INVALID );

            require( !airdrops[id].awarded[_recipient], ERROR_AWARDED );

            airdrops[id].awarded[_recipient] = true;

            totalAmount += _amounts[i];

            emit Award(id, _recipient, _amounts[i]);
        }

        agent.transfer(sctAddress, _recipient, totalAmount);
    }

    /**
     * @notice Claim awards on behalf of recipients
     * @param _id Airdrop ids
     * @param _recipients Recepients of award
     * @param _amounts The token amounts
     * @param _proofs Merkle proofs
     * @param _proofLengths Merkle proof lengths
     */
    function awardToMany(uint256 _id, address[] _recipients, uint256[] _amounts, bytes _proofs, uint256[] _proofLengths) public {

        uint256 marker = 32;

        for (uint256 i = 0; i < _recipients.length; i++) {
            address recipient = _recipients[i];

            if( airdrops[_id].awarded[recipient] )
                continue;

            bytes32[] memory proof = extractProof(_proofs, marker, _proofLengths[i]);
            marker += _proofLengths[i]*32;

            bytes32 hash = keccak256(abi.encodePacked(recipient, _amounts[i]));
            if( !validate(airdrops[_id].root, proof, hash) )
                continue;

            airdrops[_id].awarded[recipient] = true;

            agent.transfer(sctAddress, recipient, _amounts[i]);

            emit Award(_id, recipient, _amounts[i]);
        }

    }

    function extractProof(bytes _proofs, uint256 _marker, uint256 proofLength) public pure returns (bytes32[] proof) {

        proof = new bytes32[](proofLength);

        bytes32 el;

        for (uint256 j = 0; j < proofLength; j++) {
            assembly {
                el := mload(add(_proofs, _marker))
            }
            proof[j] = el;
            _marker += 32;
        }

    }

    function validate(bytes32 root, bytes32[] proof, bytes32 hash) public pure returns (bool) {

        for (uint256 i = 0; i < proof.length; i++) {
            if (hash < proof[i]) {
                hash = keccak256(abi.encodePacked(hash, proof[i]));
            } else {
                hash = keccak256(abi.encodePacked(proof[i], hash));
            }
        }

        return hash == root;
    }

    /**
     * @notice Check if address:`_recipient` awarded in airdrop:`_id`
     * @param _id Airdrop id
     * @param _recipient Recipient to check
     */
    function awarded(uint256 _id, address _recipient) public view returns(bool) {
        return airdrops[_id].awarded[_recipient];
    }
}
