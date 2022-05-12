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

        xCitadelLocker.setBoost(1000, 10000, address(2));
        // check if set
        assertEq(xCitadelLocker.nextMaximumBoostPayment(), 1000);
        assertEq(xCitadelLocker.nextBoostRate(), 10000);
        assertEq(xCitadelLocker.boostPayment(), address(2));

        vm.expectRevert("over max payment");
        xCitadelLocker.setBoost(2000, 50000, address(3)); //max 15%
        // check if nothing is changed
        assertEq(xCitadelLocker.nextMaximumBoostPayment(), 1000);
        assertEq(xCitadelLocker.nextBoostRate(), 10000);
        assertEq(xCitadelLocker.boostPayment(), address(2));

        vm.expectRevert("over max rate");
        xCitadelLocker.setBoost(1200, 50000, address(3)); //max 3x
        // check if nothing is changed
        assertEq(xCitadelLocker.nextMaximumBoostPayment(), 1000);
        assertEq(xCitadelLocker.nextBoostRate(), 10000);
        assertEq(xCitadelLocker.boostPayment(), address(2));

        vm.expectRevert("invalid address");
        xCitadelLocker.setBoost(1200, 20000, address(0)); //max 3x
        // check if nothing is changed
        assertEq(xCitadelLocker.nextMaximumBoostPayment(), 1000);
        assertEq(xCitadelLocker.nextBoostRate(), 10000);
        assertEq(xCitadelLocker.boostPayment(), address(2));

        vm.stopPrank();

    }
}