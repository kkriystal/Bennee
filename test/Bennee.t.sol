// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { Test, console } from "forge-std/Test.sol";
import { Bennee } from "../contracts/Bennee.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import { MockBennee } from "./MockBennee.sol";
import { TestUsdt } from "./TestUsdt.sol";

contract BenneeTest is Test {
    using SafeERC20 for IERC20;
    using MessageHashUtils for bytes32;

    Bennee public bennee;
    MockBennee public token;
    TestUsdt public testUsdt;

    IERC20 ASSET;
    uint256 private constant PPM = 1_000_000;
    address private constant OWNER      = 0xC0FC8954c62A45c3c0a13813Bd2A10d88D70750D; // prettier-ignore
    address private constant LENDER_1   = 0x23C7a56C43610CaAaa6dE11E60EF662CfdEde242; // prettier-ignore
    address private constant LENDER_2   = 0x3284cb59c9e03FdA920B31F22A692Bf7B93377F7; // prettier-ignore
    address private constant LENDER_3   = 0x0490D1B2E5B3aEFf13374c583A65fBE774548263; // prettier-ignore
    address private constant BORROWER_1 = 0x55F2755aA598FAD11C24C4e40E7658339d8f8eC9;
    address private constant BORROWER_2 = 0x12eF0F1C99D8FD50fFd37cCd12B09Ef7f1213269;
    uint256 private constant ONE_DAY = 86400;
    uint256 private constant ONE_MONTH_SECONDS = 2628000;

    uint256 fxRate;
    uint256 fxPercentage;
    uint256 privateKey;
    address public SIGNER;

    //--------------------------------------------------------------------//

    // uint256 amount;
    uint256 tenure = 300;
    uint256 interestPPM = 130_000;
    uint256 repayWindow = 30;

    //--------------------------------------------------------------------//

    uint256 amount1 = 2000 * 10 ** 6;
    uint256 tenure1 = 60;
    uint256 interestPPM1 = 50_000;
    uint256 repayWindow1 = 30;

    function setUp() public {
        privateKey = vm.envUint("PRIVATE_KEY");
        SIGNER = vm.addr(privateKey);
        fxRate = 15 * PPM;
        fxPercentage = 30_000;
        token = new MockBennee();
        testUsdt = new TestUsdt();

        ASSET = IERC20(address(testUsdt));

        bennee = new Bennee(address(token), ASSET, OWNER, SIGNER, interestPPM, fxRate, fxPercentage);

        // mint bennee token to borrower
        token.mint(BORROWER_1, 1000000000000e18);
        token.mint(BORROWER_2, 1000000000000e18);
        // give mock funds to addresses
        deal(address(ASSET), LENDER_1, 10_000_000 * 10 ** 6);
        deal(address(ASSET), LENDER_2, 10_000_000 * 10 ** 6);
        deal(address(ASSET), LENDER_3, 10_000_000 * 10 ** 6);
        deal(address(ASSET), address(bennee), 10_000_000 * 10 ** 6);
    }

    function test_Request(uint256 amount) external {
        if (amount < 1e6 || amount > type(uint224).max) {
            return;
        }
        uint256 deadline = block.timestamp + 2 minutes;
        (uint8 v, bytes32 r, bytes32 s) = _verifySignature(BORROWER_1, amount, tenure, repayWindow, deadline);

        vm.startPrank(BORROWER_1);
        bennee.request(amount, tenure, repayWindow, deadline, v, r, s);

        (
            uint256 borrowAmount,
            uint256 insuranceRatePPM,
            uint256 amountWithInterest,
            uint256 _tenure,
            uint256 repaymentWindow,
            uint256 repayAmountPerWindow,
            ,
            ,
            ,
            ,
            ,
            ,
            ,

        ) = bennee.borrowInfo(BORROWER_1, 1);

        uint256 perDayinterest = ((amount * insuranceRatePPM) / 365) / PPM;

        uint256 expectedAmountWithInterest = amount + (perDayinterest * tenure);
        uint256 _repayPerWindow = (amount / tenure) + (repayWindow * perDayinterest);

        assertEq(amount, borrowAmount, "borrow amount");
        assertEq(interestPPM, insuranceRatePPM, "interestPPM");
        assertEq(expectedAmountWithInterest, amountWithInterest, "amount with interest");
        assertEq(tenure, _tenure, "tenure");
        assertEq(repayWindow, repaymentWindow, "repayment window");
        assertEq(_repayPerWindow, repayAmountPerWindow, "repayment per window");

        vm.stopPrank();
        deadline = block.timestamp + 2 minutes;
        (v, r, s) = _verifySignature(BORROWER_2, amount, tenure, repayWindow, deadline);

        vm.startPrank(BORROWER_2);
        bennee.request(amount, tenure, repayWindow, deadline, v, r, s);

        vm.stopPrank();
    }

    function test_CancelRequest(uint256 amount) external {
        if (amount < 1e6 || amount > 1_000_000e6) {
            return;
        }

        uint256 deadline = block.timestamp + 2 minutes;
        (uint8 v, bytes32 r, bytes32 s) = _verifySignature(BORROWER_1, amount, tenure, repayWindow, deadline);

        vm.startPrank(BORROWER_1);
        bennee.request(amount, tenure, repayWindow, deadline, v, r, s);
        vm.stopPrank();

        vm.startPrank(LENDER_1);
        ASSET.forceApprove(address(bennee), type(uint256).max);
        bennee.supply(BORROWER_1, 1, amount / 2); // half of amount
        vm.stopPrank();

        vm.startPrank(BORROWER_1);
        bytes4 selector = bytes4(keccak256("NotAllowed()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        bennee.cancelRequest(1);

        vm.stopPrank();

        deadline = block.timestamp + 2 minutes;
        (v, r, s) = _verifySignature(BORROWER_2, amount, tenure, repayWindow, deadline);

        vm.startPrank(BORROWER_2);
        bennee.request(amount, tenure, repayWindow, deadline, v, r, s);
        bennee.cancelRequest(1);

        selector = bytes4(keccak256("NotAllowed()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        bennee.cancelRequest(1);

        vm.stopPrank();
    }

    function test_Supply(uint256 amount) external {
        if (amount < 1e6 || amount > 1_000_000e6) {
            return;
        }

        uint256 deadline = block.timestamp + 2 minutes;
        (uint8 v, bytes32 r, bytes32 s) = _verifySignature(BORROWER_1, amount, tenure, repayWindow, deadline);

        vm.startPrank(BORROWER_1);
        bennee.request(amount, tenure, repayWindow, deadline, v, r, s);

        (
            uint256 borrowAmount,
            uint256 insuranceRatePPM,
            uint256 amountWithInterest,
            uint256 _tenure,
            uint256 repaymentWindow,
            uint256 repayAmountPerWindow,
            ,
            ,
            ,
            ,
            ,
            ,
            ,

        ) = bennee.borrowInfo(BORROWER_1, 1);

        uint256 perDayinterest = ((amount * insuranceRatePPM) / 365) / PPM;

        uint256 expectedAmountWithInterest = amount + (perDayinterest * tenure);
        uint256 _repayPerWindow = (amount / tenure) + (repayWindow * perDayinterest);

        assertEq(amount, borrowAmount, "borrow amount");
        assertEq(interestPPM, insuranceRatePPM, "interestPPM");
        assertEq(expectedAmountWithInterest, amountWithInterest, "amount with interest");
        assertEq(tenure, _tenure, "tenure");
        assertEq(repayWindow, repaymentWindow, "repayment window");
        assertEq(_repayPerWindow, repayAmountPerWindow, "repayment per window");

        vm.stopPrank();

        vm.startPrank(LENDER_1);
        ASSET.forceApprove(address(bennee), type(uint256).max);
        bennee.supply(BORROWER_1, 1, amount / 3); // half of amount
        vm.stopPrank();

        vm.startPrank(LENDER_2);
        ASSET.forceApprove(address(bennee), type(uint256).max);
        bennee.supply(BORROWER_1, 1, amount / 3);
        vm.stopPrank();

        vm.startPrank(LENDER_3);
        ASSET.forceApprove(address(bennee), type(uint256).max);
        bennee.supply(BORROWER_1, 1, (amount - amount / 3));

        bytes4 selector = bytes4(keccak256("ThresholdReached()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        bennee.supply(BORROWER_1, 1, (amount - amount / 3));
        vm.stopPrank();
    }

    function test_Borrow(uint256 amount) external {
        if (amount < 1e6 || amount > 1_000_000e6) {
            return;
        }

        uint256 deadline = block.timestamp + 2 minutes;
        (uint8 v, bytes32 r, bytes32 s) = _verifySignature(BORROWER_1, amount, tenure, repayWindow, deadline);

        vm.startPrank(BORROWER_1);
        bennee.request(amount, tenure, repayWindow, deadline, v, r, s);

        (
            uint256 borrowAmount,
            uint256 insuranceRatePPM,
            uint256 amountWithInterest,
            uint256 _tenure,
            uint256 repaymentWindow,
            uint256 repayAmountPerWindow,
            ,
            ,
            ,
            ,
            ,
            ,
            ,

        ) = bennee.borrowInfo(BORROWER_1, 1);

        uint256 perDayinterest = ((amount * insuranceRatePPM) / 365) / PPM;
        uint256 expectedAmountWithInterest = amount + (perDayinterest * tenure);
        uint256 _repayPerWindow = (amount / tenure) + (repayWindow * perDayinterest);

        assertEq(amount, borrowAmount, "borrow amount");
        assertEq(interestPPM, insuranceRatePPM, "interestPPM");
        assertEq(expectedAmountWithInterest, amountWithInterest, "amount with interest");
        assertEq(tenure, _tenure, "tenure");
        assertEq(repayWindow, repaymentWindow, "repayment window");
        assertEq(_repayPerWindow, repayAmountPerWindow, "repayment per window");

        vm.stopPrank();

        vm.startPrank(LENDER_1);
        ASSET.forceApprove(address(bennee), type(uint256).max);
        bennee.supply(BORROWER_1, 1, amount / 2); // half of amount
        vm.stopPrank();

        vm.startPrank(BORROWER_1);
        bytes4 selector = bytes4(keccak256("ThresholdNotReached()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        bennee.borrow(1);

        vm.stopPrank();

        vm.startPrank(LENDER_2);
        ASSET.forceApprove(address(bennee), type(uint256).max);
        bennee.supply(BORROWER_1, 1, amount);
        vm.stopPrank();

        vm.startPrank(BORROWER_1);
        uint256 balBefore = token.balanceOf(BORROWER_1);

        bennee.borrow(1);

        uint256 balAfter = token.balanceOf(BORROWER_1);
        uint expectedTokenBalance = (amount * bennee.fxRateToToken(ASSET)) / PPM;
        assertEq(balAfter - balBefore, expectedTokenBalance);

        selector = bytes4(keccak256("AlreadyBorrowed()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        bennee.borrow(1);

        vm.stopPrank();
    }

    function test_Repay() external {
        uint256 amount = 1000e6;
        if (amount < 1e6 || amount > 3_000_000e6) {
            return;
        }

        uint256 deadline = block.timestamp + 2 minutes;
        (uint8 v, bytes32 r, bytes32 s) = _verifySignature(BORROWER_1, amount, tenure, repayWindow, deadline);

        vm.startPrank(BORROWER_1);
        bennee.request(amount, tenure, repayWindow, deadline, v, r, s);
        bennee.borrowInfo(BORROWER_1, 1);
        vm.stopPrank();

        vm.startPrank(LENDER_1);
        ASSET.forceApprove(address(bennee), type(uint256).max);
        bennee.supply(BORROWER_1, 1, amount); // half of amount
        vm.stopPrank();

        vm.startPrank(BORROWER_1);
        uint256 balBefore = token.balanceOf(BORROWER_1);
        bennee.borrow(1);
        uint256 balAfter = token.balanceOf(BORROWER_1);
        uint expectedTokenBalance = (amount * bennee.fxRateToToken(ASSET)) / PPM;
        assertEq(balAfter - balBefore, expectedTokenBalance);

        (
            uint256 _borrowAmount,
            ,
            uint256 _amountWithInterest,
            uint256 __tenure,
            uint256 _repaymentWindow,
            uint256 _repayAmountPerWindow,
            uint256 _liquidity,
            uint256 _startTime,
            uint256 _lastRepayTime,
            uint256 _repaidAmount,
            uint256 _endTime,
            ,
            bool _hasBorrowed,
            bool _hasRepaid
        ) = bennee.borrowInfo(BORROWER_1, 1);

        vm.warp(block.timestamp + 100 days);

        uint256 repay_Amount = (_repayAmountPerWindow *
            (__tenure / _repaymentWindow) *
            bennee.fxRateFromToken(ASSET) *
            1e12) / PPM;

        bennee.repay(1);
        (
            _borrowAmount,
            ,
            _amountWithInterest,
            __tenure,
            _repaymentWindow,
            _repayAmountPerWindow,
            _liquidity,
            _startTime,
            _lastRepayTime,
            _repaidAmount,
            _endTime,
            ,
            _hasBorrowed,
            _hasRepaid
        ) = bennee.borrowInfo(BORROWER_1, 1);

        vm.stopPrank();

        vm.startPrank(BORROWER_1);
        vm.warp(block.timestamp + 700 days);
        repay_Amount =
            (_repayAmountPerWindow * (__tenure / _repaymentWindow) * bennee.fxRateFromToken(ASSET) * 1e12) /
            PPM;

        bennee.repay(1);

        vm.stopPrank();

        vm.startPrank(LENDER_1);
        bennee.withdraw(1, BORROWER_1);
        (
            _borrowAmount,
            ,
            _amountWithInterest,
            __tenure,
            _repaymentWindow,
            _repayAmountPerWindow,
            _liquidity,
            _startTime,
            _lastRepayTime,
            _repaidAmount,
            _endTime,
            ,
            _hasBorrowed,
            _hasRepaid
        ) = bennee.borrowInfo(BORROWER_1, 1);
        (uint lendAmount1, uint accruedAmount1) = bennee.lendInfo(1, LENDER_1);
        (lendAmount1, accruedAmount1) = bennee.lendInfo(1, LENDER_1);
        (lendAmount1, accruedAmount1) = bennee.lendInfo(1, LENDER_1);

        vm.stopPrank();
    }

    function testUpdateToFx() external {
        uint256 newRate = bennee.fxRateToToken(ASSET) + ((bennee.fxRateToToken(ASSET) * 10000) / PPM);
        bytes4 selector = bytes4(keccak256("OnlyScheduler()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        bennee.updateToFx(newRate); // new value should be in PPM

        vm.startPrank(bennee.fxScheduler());
        selector = bytes4(keccak256("LessThanADay()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        bennee.updateToFx(newRate);

        vm.warp(block.timestamp + 1 days);
        bennee.updateToFx(newRate);

        vm.warp(block.timestamp + 2 days);

        newRate = bennee.fxRateToToken(ASSET) + ((bennee.fxRateToToken(ASSET) * 13) / 10);
        selector = bytes4(keccak256("InvalidFxRate()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        bennee.updateToFx(newRate);
        vm.stopPrank();
    }

    function testChangeSigner() external {
        vm.startPrank(OWNER);

        bennee.changeSigner(address(2));
        assertEq(bennee.signer(), address(2));
        bytes4 selector = bytes4(keccak256("IdenticalValue()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        bennee.changeSigner(address(2));

        selector = bytes4(keccak256("ZeroAddress()"));
        vm.expectRevert(abi.encodeWithSelector(selector));

        bennee.changeSigner(address(0));
        vm.stopPrank();
    }

    function testChangeFxScheduler() external {
        bytes4 selector = bytes4(keccak256("OwnableUnauthorizedAccount(address)"));
        vm.expectRevert(abi.encodeWithSelector(selector, address(this)));
        bennee.changeFxScheduler(address(2));
        vm.startPrank(OWNER);
        bennee.changeFxScheduler(address(2));
        assertEq(bennee.fxScheduler(), address(2));

        selector = bytes4(keccak256("IdenticalValue()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        bennee.changeFxScheduler(address(2));

        selector = bytes4(keccak256("ZeroAddress()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        bennee.changeFxScheduler(address(0));
        vm.stopPrank();
    }

    function _verifySignature(
        address _user,
        uint256 _amount,
        uint256 _tenure,
        uint256 _repayWindow,
        uint256 _deadline
    ) private returns (uint8, bytes32, bytes32) {
        vm.startPrank(SIGNER);

        bytes32 mhash = keccak256(abi.encodePacked(_user, _amount, _tenure, _repayWindow, _deadline));
        bytes32 msgHash = mhash.toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);

        vm.stopPrank();

        return (v, r, s);
    }
}
