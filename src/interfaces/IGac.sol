// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IGac {

    function paused() external view returns (bool);
    function hasRole(bytes32 role, address account) external view returns (bool);
}
