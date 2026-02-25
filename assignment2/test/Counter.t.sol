// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MyToken} from "../src/Mytoken.sol";

contract MyTokenTest is Test {

    MyToken public token;

    address deployer = address(1);
    address alice    = address(2);
    address bob      = address(3);

    uint256 constant INITIAL_SUPPLY = 1_000_000 ether;

    function setUp() public {
        vm.prank(deployer);
        token = new MyToken("MyToken", "MTK", 18, INITIAL_SUPPLY);
    }

    // ─── Constructor ──────────────────────────────────────────────────────────

    function test_MetadataIsSetCorrectly() public view {
        assertEq(token.name(),     "MyToken");
        assertEq(token.symbol(),   "MTK");
        assertEq(token.decimals(), 18);
    }

    function test_InitialSupplyMintedToDeployer() public view {
        assertEq(token.totalSupply(),        INITIAL_SUPPLY);
        assertEq(token.balanceOf(deployer),  INITIAL_SUPPLY);
    }

    // ─── transfer ─────────────────────────────────────────────────────────────

    function test_TransferTokens() public {
        uint256 amount = 100 ether;

        vm.prank(deployer);
        token.transfer(alice, amount);

        assertEq(token.balanceOf(alice),    amount);
        assertEq(token.balanceOf(deployer), INITIAL_SUPPLY - amount);
    }

    function test_TransferEmitsEvent() public {
        vm.prank(deployer);
        vm.expectEmit(true, true, false, true);
        emit MyToken.Transfer(deployer, alice, 50 ether);
        token.transfer(alice, 50 ether);
    }

    function test_TransferRevertsIfInsufficientBalance() public {
        vm.prank(alice); // alice has 0 tokens
        vm.expectRevert();
        token.transfer(bob, 1 ether);
    }

    // ─── approve / allowance ──────────────────────────────────────────────────

    function test_ApproveSetAllowance() public {
        vm.prank(deployer);
        token.approve(alice, 200 ether);

        assertEq(token.allowance(deployer, alice), 200 ether);
    }

    function test_ApproveEmitsEvent() public {
        vm.prank(deployer);
        vm.expectEmit(true, true, false, true);
        emit MyToken.Approval(deployer, alice, 200 ether);
        token.approve(alice, 200 ether);
    }

    // ─── transferFrom ─────────────────────────────────────────────────────────

    function test_TransferFromSpendAllowance() public {
        uint256 amount = 300 ether;

        // deployer approves alice
        vm.prank(deployer);
        token.approve(alice, amount);

        // alice pulls tokens from deployer to bob
        vm.prank(alice);
        token.transferFrom(deployer, bob, amount);

        assertEq(token.balanceOf(bob),              amount);
        assertEq(token.balanceOf(deployer),         INITIAL_SUPPLY - amount);
        assertEq(token.allowance(deployer, alice),  0); // allowance consumed
    }

    function test_TransferFromEmitsEvent() public {
        vm.prank(deployer);
        token.approve(alice, 100 ether);

        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit MyToken.Transfer(deployer, bob, 100 ether);
        token.transferFrom(deployer, bob, 100 ether);
    }

    function test_TransferFromRevertsIfAllowanceExceeded() public {
        vm.prank(deployer);
        token.approve(alice, 50 ether);

        vm.prank(alice);
        vm.expectRevert();
        token.transferFrom(deployer, bob, 100 ether); // more than approved
    }

    function test_TransferFromRevertsIfInsufficientBalance() public {
        // alice approves bob for a large amount but alice has no tokens
        vm.prank(alice);
        token.approve(bob, 500 ether);

        vm.prank(bob);
        vm.expectRevert();
        token.transferFrom(alice, bob, 500 ether);
    }
}
