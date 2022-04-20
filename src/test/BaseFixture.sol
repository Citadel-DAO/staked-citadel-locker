// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "ds-test/test.sol";

import {Utils} from "./utils/Utils.sol";
import {StakedCitadelLocker} from "../StakedCitadelLocker.sol";
import {GlobalAccessControl} from "../mocks/GlobalAccessControl.sol";

contract BaseFixture is DSTest, Utils {
    CheatCodes constant vm = CheatCodes(HEVM_ADDRESS);

    bytes32 public constant CONTRACT_GOVERNANCE_ROLE =
        keccak256("CONTRACT_GOVERNANCE_ROLE");
    bytes32 public constant TREASURY_GOVERNANCE_ROLE =
        keccak256("TREASURY_GOVERNANCE_ROLE");

    bytes32 public constant TECH_OPERATIONS_ROLE =
        keccak256("TECH_OPERATIONS_ROLE");
    bytes32 public constant POLICY_OPERATIONS_ROLE =
        keccak256("POLICY_OPERATIONS_ROLE");
    bytes32 public constant TREASURY_OPERATIONS_ROLE =
        keccak256("TREASURY_OPERATIONS_ROLE");

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");

    bytes32 public constant BLOCKLIST_MANAGER_ROLE =
        keccak256("BLOCKLIST_MANAGER_ROLE");
    bytes32 public constant BLOCKLISTED_ROLE = keccak256("BLOCKLISTED_ROLE");

    bytes32 public constant CITADEL_MINTER_ROLE =
        keccak256("CITADEL_MINTER_ROLE");

    uint256 public constant ONE = 1 ether;

    // ==================
    // ===== Actors =====
    // ==================

    address immutable governance = getAddress("governance");
    address immutable techOps = getAddress("techOps");
    address immutable policyOps = getAddress("policyOps");
    address immutable guardian = getAddress("guardian");
    address immutable keeper = getAddress("keeper");
    address immutable treasuryVault = getAddress("treasuryVault");
    address immutable treasuryOps = getAddress("treasuryOps");

    address immutable citadelTree = getAddress("citadelTree");
    address immutable citadelMinter = getAddress("citadelMinter");
    address immutable xCitadel = getAddress("xCitadel");

    address immutable rando = getAddress("rando");

    address immutable whale = getAddress("whale");
    address immutable shrimp = getAddress("shrimp");
    address immutable shark = getAddress("shark");

    GlobalAccessControl gac = new GlobalAccessControl();
    StakedCitadelLocker xCitadelLocker = new StakedCitadelLocker();

    function getSelector(string memory _func) public pure returns (bytes4) {
        return bytes4(keccak256(bytes(_func)));
    }

    function setUp() public virtual {
        // Labels
        vm.label(address(this), "this");

        vm.label(governance, "governance");
        vm.label(policyOps, "policyOps");
        vm.label(keeper, "keeper");
        vm.label(guardian, "guardian");
        vm.label(treasuryVault, "treasuryVault");

        vm.label(rando, "rando");

        vm.label(address(gac), "gac");
        vm.label(citadelMinter, "citadelMinter"); // Using a random address for the purposes of these tests
        vm.label(xCitadel, "xCitadel"); // Using a random address for the purposes of these tests

        vm.label(whale, "whale"); // whale attempts large token actions, testing upper bounds
        vm.label(shrimp, "shrimp"); // shrimp attempts small token actions, testing lower bounds
        vm.label(shark, "shark"); // shark attempts malicious actions

        // Initialization
        vm.startPrank(governance);
        gac.initialize(governance);

        xCitadelLocker.initialize(
            xCitadel,
            address(gac),
            "Vote Locked xCitadel",
            "vlCTDL"
        );

        // Grant roles
        gac.grantRole(CONTRACT_GOVERNANCE_ROLE, governance);
        gac.grantRole(TREASURY_GOVERNANCE_ROLE, treasuryVault);

        gac.grantRole(TECH_OPERATIONS_ROLE, techOps);
        gac.grantRole(TREASURY_OPERATIONS_ROLE, treasuryOps);
        gac.grantRole(POLICY_OPERATIONS_ROLE, policyOps);

        gac.grantRole(CITADEL_MINTER_ROLE, citadelMinter);
        gac.grantRole(CITADEL_MINTER_ROLE, governance); // To handle initial supply, remove atomically.

        gac.grantRole(PAUSER_ROLE, guardian);
        gac.grantRole(UNPAUSER_ROLE, techOps);
        vm.stopPrank();
    }
}

// Cheatcodes reference
interface CheatCodes {
    // Set block.timestamp
    function warp(uint256) external;

    // Set block.number
    function roll(uint256) external;

    // Set block.basefee
    function fee(uint256) external;

    // Set block.chainid
    function chainId(uint256) external;

    // Loads a storage slot from an address
    function load(address account, bytes32 slot) external returns (bytes32);

    // Stores a value to an address' storage slot
    function store(address account, bytes32 slot, bytes32 value) external;

    // Signs data
    function sign(uint256 privateKey, bytes32 digest) external returns (uint8 v, bytes32 r, bytes32 s);

    // Computes address for a given private key
    function addr(uint256 privateKey) external returns (address);

    // Gets the nonce of an account
    function getNonce(address account) external returns (uint64);

    // Sets the nonce of an account
    // The new nonce must be higher than the current nonce of the account
    function setNonce(address account, uint256 nonce) external;

    // Performs a foreign function call via terminal
    function ffi(string[] calldata) external returns (bytes memory);

    // Sets the *next* call's msg.sender to be the input address
    function prank(address) external;

    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called
    function startPrank(address) external;

    // Sets the *next* call's msg.sender to be the input address, and the tx.origin to be the second input
    function prank(address, address) external;

    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called, and the tx.origin to be the second input
    function startPrank(address, address) external;

    // Resets subsequent calls' msg.sender to be `address(this)`
    function stopPrank() external;

    // Sets an address' balance
    function deal(address who, uint256 newBalance) external;

    // Sets an address' code
    function etch(address who, bytes calldata code) external;

    // Expects an error on next call
    function expectRevert() external;
    function expectRevert(bytes calldata) external;
    function expectRevert(bytes4) external;

    // Record all storage reads and writes
    function record() external;

    // Gets all accessed reads and write slot from a recording session, for a given address
    function accesses(address) external returns (bytes32[] memory reads, bytes32[] memory writes);

    // Prepare an expected log with (bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData).
    // Call this function, then emit an event, then call a function. Internally after the call, we check if
    // logs were emitted in the expected order with the expected topics and data (as specified by the booleans)
    function expectEmit(bool, bool, bool, bool) external;

    // Mocks a call to an address, returning specified data.
    // Calldata can either be strict or a partial match, e.g. if you only
    // pass a Solidity selector to the expected calldata, then the entire Solidity
    // function will be mocked.
    function mockCall(address, bytes calldata, bytes calldata) external;

    // Clears all mocked calls
    function clearMockedCalls() external;

    // Expect a call to an address with the specified calldata.
    // Calldata can either be strict or a partial match
    function expectCall(address, bytes calldata) external;

    // Gets the bytecode for a contract in the project given the path to the contract.
    function getCode(string calldata) external returns (bytes memory);

    // Label an address in test traces
    function label(address addr, string calldata label) external;

    // When fuzzing, generate new inputs if conditional not met
    function assume(bool) external;
}
