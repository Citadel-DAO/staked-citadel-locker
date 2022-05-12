pragma solidity 0.6.12;

import {BaseFixture} from "./BaseFixture.sol";

contract LockerTest is BaseFixture {
    function setUp() public override {
        BaseFixture.setUp();
    }

    function testBasicSetFunctions() public{
        // only governance can call these functions
        vm.startPrank(governance); 
        xCitadelLocker.setStakingContract(address(1));
         // check if staking contract is set
        assertEq(xCitadelLocker.stakingProxy(), address(1));

        // revert as staking contract is already set
        vm.expectRevert("!assign");
        xCitadelLocker.setStakingContract(address(2));

        // governance can set kick incentive
        xCitadelLocker.setKickIncentive(200, 3); 

        // check if rate and delay are set
        assertEq(xCitadelLocker.kickRewardPerEpoch(), 200);
        assertEq(xCitadelLocker.kickRewardEpochDelay(), 3);

        vm.expectRevert("over max rate");
        xCitadelLocker.setKickIncentive(600, 4); //max 5% per epoch
        assertEq(xCitadelLocker.kickRewardPerEpoch(), 200);
        assertEq(xCitadelLocker.kickRewardEpochDelay(), 3);

        vm.expectRevert("min delay");
        xCitadelLocker.setKickIncentive(400, 1); //minimum 2 epochs of grace
        assertEq(xCitadelLocker.kickRewardPerEpoch(), 200); 
        assertEq(xCitadelLocker.kickRewardEpochDelay(), 3);
        
        vm.stopPrank();

    }
}