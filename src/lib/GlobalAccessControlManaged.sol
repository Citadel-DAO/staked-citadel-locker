// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import {PausableUpgradeable} from "openzeppelin-contracts-upgradeable/utils/PausableUpgradeable.sol";
import "../interfaces/IGac.sol";

/**
 * @title Global Access Control Managed - Base Class
 * @notice allows inheriting contracts to leverage global access control permissions conveniently, as well as granting contract-specific pausing functionality
 */
contract GlobalAccessControlManaged is PausableUpgradeable {
    IGac public gac;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");

    /// =======================
    /// ===== Initializer =====
    /// =======================

    /**
     * @notice Initializer
     * @dev this is assumed to be used in the initializer of the inhereiting contract
     * @param _globalAccessControl global access control which is pinged to allow / deny access to permissioned calls by role
     */
    function __GlobalAccessControlManaged_init(address _globalAccessControl)
        public
        initializer
    {
        __Pausable_init_unchained();
        gac = IGac(_globalAccessControl);
    }

    /// =====================
    /// ===== Modifiers =====
    /// =====================

    function _onlyRole(bytes32 role) internal {
        require(gac.hasRole(role, msg.sender), "GAC: invalid-caller-role");
    }

    /// @dev can be pausable by GAC or local flag
    modifier gacPausable() {
        require(!gac.paused(), "global-paused");
        require(!paused(), "local-paused");
        _;
    }

    /// ================================
    /// ===== Permissioned actions =====
    /// ================================

    function pause() external {
        require(gac.hasRole(PAUSER_ROLE, msg.sender));
        _pause();
    }

    function unpause() external {
        require(gac.hasRole(UNPAUSER_ROLE, msg.sender));
        _unpause();
    }
}