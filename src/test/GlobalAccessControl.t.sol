pragma solidity 0.6.12;

import {BaseFixture} from "./BaseFixture.sol";

contract GlobalAccessControlTest is BaseFixture {
    function setUp() public override {
        BaseFixture.setUp();
    }

    function testPauseAndUnPause() public{
        vm.prank(address(1));
        vm.expectRevert("PAUSER_ROLE");
        gac.pause();

        // PAUSER_ROLE is assigned to guardian in BaseFixture
        vm.prank(guardian);
        gac.pause();

        // check if it paused
        assertTrue(gac.paused());

        vm.prank(address(1));
        vm.expectRevert("UNPAUSER_ROLE");
        gac.unpause();

        // UNPAUSER_ROLE is assigned to techOps in BaseFixture
        vm.prank(techOps);
        gac.unpause();

        // check if it unpaused
        assertTrue(!gac.paused());
    }

    function testLockerPausingFunctions() public{

        // pausing locally
        vm.prank(guardian);
        xCitadelLocker.pause();

        // Only owner functions
        vm.startPrank(governance);

        vm.expectRevert("local-paused");
        xCitadelLocker.addReward(address(1), address(2), false);

        vm.expectRevert("local-paused");
        xCitadelLocker.approveRewardDistributor(address(1), address(2), false);

        vm.expectRevert("local-paused");
        xCitadelLocker.setStakingContract(address(1));

        vm.expectRevert("local-paused");
        xCitadelLocker.setStakeLimits(0, 100e18);

        vm.expectRevert("local-paused");
        xCitadelLocker.setBoost(1000, 1000, address(1));

        vm.expectRevert("local-paused");
        xCitadelLocker.setKickIncentive(100, 1000);

        vm.expectRevert("local-paused");
        xCitadelLocker.recoverERC20(address(1), 10e18);

        vm.stopPrank();

        // Open access external/public functions
        vm.startPrank(rando);

        vm.expectRevert("local-paused");
        xCitadelLocker.lock(address(1), 1000, 6000);

        vm.expectRevert("local-paused");
        xCitadelLocker.withdrawExpiredLocksTo(address(2));

        vm.expectRevert("local-paused");
        xCitadelLocker.processExpiredLocks(true);

        vm.expectRevert("local-paused");
        xCitadelLocker.kickExpiredLocks(address(1));

        vm.expectRevert("local-paused");
        xCitadelLocker.getReward(address(1), true);

        vm.expectRevert("local-paused");
        xCitadelLocker.notifyRewardAmount(address(1), 10e18, keccak256("XCITADEL"));

        vm.stopPrank();

        // Locally un-pause
        vm.prank(techOps);
        xCitadelLocker.unpause();

        // pausing globally
        vm.prank(guardian);
        gac.pause();

        // Only owner functions
        vm.startPrank(governance);

        vm.expectRevert("global-paused");
        xCitadelLocker.addReward(address(1), address(2), false);

        vm.expectRevert("global-paused");
        xCitadelLocker.approveRewardDistributor(address(1), address(2), false);

        vm.expectRevert("global-paused");
        xCitadelLocker.setStakingContract(address(1));

        vm.expectRevert("global-paused");
        xCitadelLocker.setStakeLimits(0, 100e18);

        vm.expectRevert("global-paused");
        xCitadelLocker.setBoost(1000, 1000, address(1));

        vm.expectRevert("global-paused");
        xCitadelLocker.setKickIncentive(100, 1000);

        vm.expectRevert("global-paused");
        xCitadelLocker.recoverERC20(address(1), 10e18);

        vm.stopPrank();

        // Open access external/public functions
        vm.startPrank(rando);

        vm.expectRevert("global-paused");
        xCitadelLocker.lock(address(1), 1000, 6000);

        vm.expectRevert("global-paused");
        xCitadelLocker.withdrawExpiredLocksTo(address(2));

        vm.expectRevert("global-paused");
        xCitadelLocker.processExpiredLocks(true);

        vm.expectRevert("global-paused");
        xCitadelLocker.kickExpiredLocks(address(1));

        vm.expectRevert("global-paused");
        xCitadelLocker.getReward(address(1), true);

        vm.expectRevert("global-paused");
        xCitadelLocker.notifyRewardAmount(address(1), 10e18, keccak256("XCITADEL"));

        vm.stopPrank();

        // Globally un-pause
        vm.prank(techOps);
        gac.unpause();
    }

    function testCallerRoles() public{
        // only governance can add reward
        vm.expectRevert("GAC: invalid-caller-role");
        xCitadelLocker.addReward(address(1), address(2), false);

        vm.prank(governance);
        xCitadelLocker.addReward(address(1), address(2), false);
        
        // only governance can approve reward distributor
        vm.expectRevert("GAC: invalid-caller-role");
        xCitadelLocker.approveRewardDistributor(address(1), address(3), true);

        vm.prank(governance);
        xCitadelLocker.approveRewardDistributor(address(1), address(3), true);

        // only governance can set staking contract
        vm.expectRevert("GAC: invalid-caller-role");
        xCitadelLocker.setStakingContract(address(1));

        vm.prank(governance); 
        xCitadelLocker.setStakingContract(address(1));

        // only governance can set kick incentive
        vm.expectRevert("GAC: invalid-caller-role");
        xCitadelLocker.setKickIncentive(200, 3); 

        vm.prank(governance);
        xCitadelLocker.setKickIncentive(200, 3); 

        // only governance can set Boost
        vm.expectRevert("GAC: invalid-caller-role"); 
        xCitadelLocker.setBoost(1000, 10000, address(2));

        vm.prank(governance);
        xCitadelLocker.setBoost(1000, 10000, address(2));

        // only governance can shutdown
        vm.expectRevert("GAC: invalid-caller-role");
        xCitadelLocker.shutdown();

        vm.prank(governance);
        xCitadelLocker.shutdown();

        // only governance can recoverERC20
        vm.expectRevert("GAC: invalid-caller-role");
        xCitadelLocker.recoverERC20(address(4), 0); 

        vm.prank(governance);
        xCitadelLocker.recoverERC20(address(wbtc), 0); 

        // only governance can set stake limits
        vm.expectRevert("GAC: invalid-caller-role");
        xCitadelLocker.setStakeLimits(0, 4000);

    }
}