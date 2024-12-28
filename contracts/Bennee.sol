// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable, Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { ReentrancyGuardTransient } from "@openzeppelin/contracts/utils/ReentrancyGuardTransient.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import { IBennee } from "./IBennee.sol";

/// @title Bennee contract
/// @notice Implements lending borrowing of asset
/// @dev The contract allows you to borrow an asset and repay in multiple windows
contract Bennee is Ownable2Step, ReentrancyGuardTransient {
    using SafeERC20 for IERC20;

    /// @member borrowAmount The borrow amount of the user
    /// @member insuranceRatePPM The insurance rate
    /// @member amountWithInterest The amount and total interest collectively
    /// @member tenure The time period in days for which user wants to borrow
    /// @member repaymentWindow The time in days, after which user will repays
    /// @member repayAmountPerWindow The repayment amount per window
    /// @member liquidity The total amount lenders had paid
    /// @member startTime The borrowing start time, initiates when borrower claims amount
    /// @member lastRepayTime The last time user has repaid
    /// @member repaidAmount The total repaid amount
    /// @member endTime The end time in days when user will repays all the amounts
    /// @member borrower The address of the borrower
    /// @member hasBorrowed The true/false tells us user has borrowed his amount or not
    /// @member hasRepaid The true/false tells us user has repaid all his amounts or not
    struct BorrowInfo {
        uint256 borrowAmount;
        uint256 insuranceRatePPM;
        uint256 amountWithInterest;
        uint256 tenure;
        uint256 repaymentWindow;
        uint256 repayAmountPerWindow;
        uint256 liquidity;
        uint256 startTime;
        uint256 lastRepayTime;
        uint256 repaidAmount;
        uint256 endTime;
        address borrower;
        bool hasBorrowed;
        bool hasRepaid;
    }

    /// @member lendAmount The lend amount of the lender
    /// @member accruedAmount The total amount lender has accrued out of his amount with interest
    struct LendInfo {
        uint256 lendAmount;
        uint256 accruedAmount;
    }

    /// @dev The constant value helps in calculating percentages/amounts
    uint256 private constant PPM = 1_000_000;

    /// @dev The constant value helps in calculating percentages/amounts
    uint256 private constant NORMALIZATION_FACTOR = 1e12;

    /// @dev Returns one year days
    uint256 private constant ONE_YEAR_DAYS = 365;

    /// @dev The one day time in seconds
    uint256 private constant ONE_DAY_SECONDS = 86400;

    /// @notice The percentage value helps in calculating fxRate
    uint256 public immutable fxRatePercentage;

    /// @notice Token used for payment and repayment
    IBennee public immutable bennee;

    /// @notice The address of the asset contract e.g Usdt
    IERC20 public immutable ASSET;

    /// @notice The address of signer wallet
    address public signer;

    /// @notice The address of fxScheduler wallet
    address public fxScheduler;

    /// @notice The insurance rate that borrowers will pay
    uint256 public insuranceRatePPM;

    /// @notice The last timeStamp when fxScheduler updated the fxRate
    uint256 public timestampFx;

    /// @notice Gives us exchange rate from asset to token
    mapping(IERC20 => uint256) public fxRateToToken;

    /// @notice Gives us exchange rate from token to asset
    mapping(IERC20 => uint256) public fxRateFromToken;

    /// @notice Gives us loyality points of each user
    mapping(address => uint256) public loyalityPoints;

    /// @notice Gives borrowers info stored at unique index
    mapping(address => mapping(uint256 => BorrowInfo)) public borrowInfo;

    /// @notice Gives lenders info for the given borrow index
    mapping(uint256 => mapping(address => LendInfo)) public lendInfo;

    /// @notice Gives total borrows a user has requested
    mapping(address => uint) public userIndex;

    /// @dev Emitted when borrower posts his request for loan
    event Requested(
        address user,
        uint256 index,
        uint256 amount,
        uint256 tenure,
        uint256 interestRate,
        uint256 repaymentWIndow
    );

    /// @dev Emitted when lender supplies funds on the borrower request
    event Supplied(address lender, uint256 lendAmount, address borrower, uint256 borrowIndex);

    /// @dev Emitted when lender cancels his lends for the borrower request
    event CancelledSupply(address lender, address borrower, uint256 borrowIndex, uint256 cancelAmount);

    /// @dev Emitted when borrower borrowrs the amount
    event Borrowed(address by, uint256 borrowIndex);

    /// @dev Emitted when borrowers repay their repayment window
    event Repaid(address borrower, uint256 borrowerIndex, uint256 repayAmount);

    /// @dev Emitted when lenders withdraw their repayment window
    event Withdraw(address by, uint256 borrowIndex, address borrower, uint256 amount);

    /// @dev Emitted when lenders withdraw their repayment window, paid by contract
    event DefaultWithdraw(address by, uint256 borrowIndex, address borrower, uint256 amount);

    /// @dev Emitted when address of signer is updated
    event SignerUpdated(address oldSigner, address newSigner);

    /// @dev Emitted when borrower cancels his request
    event CancelledRequest(address by, uint256 borrowIndex);

    /// @dev Emitted when fxScheduler address is updated
    event FxSchedulerUpdated(address oldFxScheduler, address newFxSchedulerAddress);

    /// @dev Emitted when fxRate is updated
    event FxRateUpdated(address scheduler, uint256 fxRate);

    /// @dev Emitted when insurance rate is updated
    event InsuranceRateUpdated(uint256 oldInsuranceRate, uint256 newInsuranceRate);

    /// @notice Thrown when borrower borrows twice or lender cancels while borrower claimed the amount
    error AlreadyBorrowed();

    /// @notice Thrown when trying to repay, while repayment is done
    error AlreadyRepaid();

    /// @notice Thrown when repayment amount is less than needed
    error InvalidRepayAmount();

    /// @notice Thrown when borrower repays before repay window
    error PayLater();

    /// @notice Thrown when sign is invalid
    error InvalidSignature();

    /// @notice Thrown when updating an address with zero address
    error ZeroAddress();

    /// @notice Thrown when borrowing with invalid arguments
    error InvalidValues();

    /// @notice Thrown when borrower tries to borrow, while threshold limit is not reached
    error ThresholdNotReached();

    /// @notice Thrown when caller is not borrower
    error CallerNotBorrower();

    /// @notice Thrown when threshold limit is reached
    error ThresholdReached();

    /// @notice Thrown when lend cancel amount is greater than actual lend amount
    error AmountExceedsLend();

    /// @notice Thrown when lender cancels his request while already borrowed or cancelled
    error NotAllowed();

    /// @notice Thrown when updating with the same value as previously stored
    error IdenticalValue();

    /// @notice Thrown when updating variable with zero value
    error ZeroValue();

    /// @notice Thrown when repayment window is greater than tenure or their mod is not equal to zero
    error InvalidRepayWindow();

    /// @notice Thrown when caller is not scheduler
    error OnlyScheduler();

    /// @notice Thrown when updating fxRate before 24 hours
    error LessThanADay();

    /// @notice Thrown when updating fxRate with value not in the 10% range
    error InvalidFxRate();

    /// @dev Restricts when updating wallet/contract address with zero address
    modifier checkAddressZero(address which) {
        _checkAddressZero(which);
        _;
    }

    /// @dev Constructor
    /// @param benneeAddress The address of bennee token
    /// @param assetAddress The asset is the token used to lend and borrow
    /// @param owner The address of owner wallet
    /// @param signerAddress The address of signer wallet
    /// @param insuranceRateInitPPM The insurance rate in PPM
    /// @param fxRatePPMInit The exchange rate in PPM
    /// @param fxRatePercentagePPMInit The exchange rate in PPM
    constructor(
        address benneeAddress,
        IERC20 assetAddress,
        address owner,
        address signerAddress,
        uint256 insuranceRateInitPPM,
        uint256 fxRatePPMInit,
        uint256 fxRatePercentagePPMInit
    )
        Ownable(owner)
        checkAddressZero(benneeAddress)
        checkAddressZero(address(assetAddress))
        checkAddressZero(signerAddress)
    {
        if (insuranceRateInitPPM == 0 || fxRatePPMInit == 0) {
            revert ZeroValue();
        }

        ASSET = assetAddress;
        bennee = IBennee(benneeAddress);
        signer = signerAddress;
        insuranceRatePPM = insuranceRateInitPPM;
        fxRateToToken[ASSET] = fxRatePPMInit - ((fxRatePPMInit * fxRatePercentage) / PPM);
        fxRateFromToken[ASSET] = fxRatePPMInit + (fxRatePPMInit * fxRatePercentage) / PPM;
        fxRatePercentage = fxRatePercentagePPMInit;
        timestampFx = block.timestamp;
    }

    //------------------------ Borrower functions ---------------------------------//

    /// @notice Request for borrow an asset
    /// @param amountToBorrow The amount of asset user want to borrow
    /// @param tenure The time duration in days for which user wants to borrow
    /// @param repayWindow The repay window in days and it should be less than tenure
    /// @param deadline The deadline is validity of the signature
    /// @param v The `v` signature parameter
    /// @param r The `r` signature parameter
    /// @param s The `s` signature parameter
    function request(
        uint256 amountToBorrow,
        uint256 tenure,
        uint256 repayWindow,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 encodedMessageHash = keccak256(
            abi.encodePacked(msg.sender, amountToBorrow, tenure, repayWindow, deadline)
        );
        // The borrower must be authorised to request for loan
        if (signer != ECDSA.recover(MessageHashUtils.toEthSignedMessageHash(encodedMessageHash), v, r, s)) {
            revert InvalidSignature();
        }

        uint256 index = ++userIndex[msg.sender];

        if (amountToBorrow < PPM || tenure == 0 || repayWindow == 0) {
            revert InvalidValues();
        }

        if (repayWindow > tenure || tenure % repayWindow != 0) {
            revert InvalidRepayWindow();
        }

        uint256 perDayinterest = ((amountToBorrow * insuranceRatePPM) / ONE_YEAR_DAYS) / PPM;
        borrowInfo[msg.sender][index] = BorrowInfo({
            borrowAmount: amountToBorrow,
            insuranceRatePPM: insuranceRatePPM,
            amountWithInterest: amountToBorrow + (perDayinterest * tenure),
            tenure: tenure,
            endTime: 0,
            repaymentWindow: repayWindow,
            liquidity: 0,
            borrower: msg.sender,
            startTime: 0,
            lastRepayTime: 0,
            repaidAmount: 0,
            repayAmountPerWindow: (amountToBorrow / tenure) + (repayWindow * perDayinterest),
            hasBorrowed: false,
            hasRepaid: false
        });

        emit Requested(msg.sender, index, amountToBorrow, tenure, insuranceRatePPM, repayWindow);
    }

    /// @notice Redeems borrow amount callable by borrower of that borrow index
    /// @param borrowIndex The borrower request index
    function borrow(uint256 borrowIndex) external nonReentrant {
        mapping(uint256 => BorrowInfo) storage infoAtIndex = borrowInfo[msg.sender];
        BorrowInfo memory info = infoAtIndex[borrowIndex];

        if (info.borrower != msg.sender) {
            revert CallerNotBorrower();
        }

        if (info.liquidity != info.borrowAmount) {
            revert ThresholdNotReached();
        }

        if (info.hasBorrowed) {
            revert AlreadyBorrowed();
        }

        infoAtIndex[borrowIndex].hasBorrowed = true;
        infoAtIndex[borrowIndex].startTime = block.timestamp;
        infoAtIndex[borrowIndex].lastRepayTime = block.timestamp;
        infoAtIndex[borrowIndex].endTime = block.timestamp + (info.tenure * ONE_DAY_SECONDS);
        bennee.mint(msg.sender, (info.borrowAmount * fxRateToToken[ASSET]) / PPM);

        emit Borrowed(msg.sender, borrowIndex);
    }

    /// @notice Cancels borrow request only callable by borrower of borrow index
    /// @param borrowIndex The borrower request index
    function cancelRequest(uint256 borrowIndex) external nonReentrant {
        BorrowInfo memory borrowerInfo = borrowInfo[msg.sender][borrowIndex];

        if (borrowerInfo.liquidity > 0 || borrowerInfo.hasBorrowed || borrowerInfo.borrower != msg.sender) {
            revert NotAllowed();
        }

        delete borrowInfo[msg.sender][borrowIndex];

        emit CancelledRequest(msg.sender, borrowIndex);
    }

    /// @notice Repays amount of the lender for the repay windows passed
    /// @param borrowIndex The borrower request index
    function repay(uint256 borrowIndex) external {
        mapping(uint256 => BorrowInfo) storage infoAtIndex = borrowInfo[msg.sender];
        BorrowInfo memory borrowerInfo = infoAtIndex[borrowIndex];

        if (borrowerInfo.hasRepaid) {
            revert AlreadyRepaid();
        }

        uint256 paymentWindowPassed = (
            block.timestamp >= borrowerInfo.endTime
                ? (borrowerInfo.endTime - borrowerInfo.lastRepayTime)
                : (block.timestamp - borrowerInfo.lastRepayTime)
        ) / (ONE_DAY_SECONDS * borrowerInfo.repaymentWindow);

        if (paymentWindowPassed == 0) {
            revert PayLater();
        }

        if (paymentWindowPassed > 1) {
            loyalityPoints[msg.sender] += paymentWindowPassed - 1;
        }

        uint256 repayAmount = paymentWindowPassed * borrowerInfo.repayAmountPerWindow;
        bennee.burn(msg.sender, (repayAmount * fxRateFromToken[ASSET] * NORMALIZATION_FACTOR) / PPM);
        infoAtIndex[borrowIndex].repaidAmount += repayAmount;
        infoAtIndex[borrowIndex].lastRepayTime += paymentWindowPassed * borrowerInfo.repaymentWindow * ONE_DAY_SECONDS;

        emit Repaid(msg.sender, borrowIndex, repayAmount);
    }

    //------------------------ Lenders functions ---------------------------------//

    /// @notice Supplies an amount of asset to the  borrower
    /// @param borrower The address of the borrower
    /// @param borrowIndex The borrower request index
    /// @param supplyAmount The supply amount provided by user
    function supply(address borrower, uint256 borrowIndex, uint256 supplyAmount) external nonReentrant {
        mapping(uint256 => BorrowInfo) storage infoAtIndex = borrowInfo[borrower];
        BorrowInfo memory borrowerInfo = infoAtIndex[borrowIndex];

        if (borrowerInfo.liquidity == borrowerInfo.borrowAmount) {
            revert ThresholdReached();
        }

        if (borrowerInfo.liquidity + supplyAmount > borrowerInfo.borrowAmount) {
            supplyAmount = borrowerInfo.borrowAmount - borrowerInfo.liquidity;
        }

        ASSET.safeTransferFrom(msg.sender, address(this), supplyAmount);
        infoAtIndex[borrowIndex].liquidity = borrowerInfo.liquidity + supplyAmount;
        lendInfo[borrowIndex][msg.sender].lendAmount = lendInfo[borrowIndex][msg.sender].lendAmount + supplyAmount;

        emit Supplied(msg.sender, supplyAmount, borrower, borrowIndex);
    }

    /// @notice Lenders withdraw their repayment window
    /// @param borrowIndex The borrower request index
    /// @param borrower The address of the borrower
    function withdraw(uint256 borrowIndex, address borrower) external nonReentrant {
        LendInfo memory lenderInfo = lendInfo[borrowIndex][msg.sender];
        BorrowInfo memory borrowerInfo = borrowInfo[borrower][borrowIndex];
        uint256 share = (borrowerInfo.repaidAmount * lenderInfo.lendAmount) / borrowerInfo.borrowAmount;

        if (lenderInfo.accruedAmount < share) {
            uint256 amount = share - lenderInfo.accruedAmount;
            lendInfo[borrowIndex][msg.sender].accruedAmount += amount;
            ASSET.safeTransfer(msg.sender, amount);

            emit Withdraw(msg.sender, borrowIndex, borrower, amount);
        }

        uint256 paymentWindowPassed = (
            block.timestamp >= borrowerInfo.endTime
                ? (borrowerInfo.endTime - borrowerInfo.startTime)
                : (block.timestamp - borrowerInfo.startTime)
        ) / (ONE_DAY_SECONDS * borrowerInfo.repaymentWindow);
        uint256 totalAmount = (paymentWindowPassed * borrowerInfo.repayAmountPerWindow * lenderInfo.lendAmount) /
            borrowerInfo.borrowAmount;
        share = totalAmount - lendInfo[borrowIndex][msg.sender].accruedAmount;

        if (share > 0) {
            lendInfo[borrowIndex][msg.sender].accruedAmount += share;
            ASSET.safeTransfer(msg.sender, share);

            emit DefaultWithdraw(msg.sender, borrowIndex, borrower, share);
        }
    }

    /// @notice Cancels supply for the borrower, if borrower has not claimed amount
    /// @param borrower The address of the borrower
    /// @param borrowIndex The borrower request index
    /// @param amount The amount lender wants to cancel
    function cancelSupply(address borrower, uint256 borrowIndex, uint256 amount) external nonReentrant {
        BorrowInfo memory borrowerInfo = borrowInfo[borrower][borrowIndex];
        LendInfo memory lenderInfo = lendInfo[borrowIndex][msg.sender];

        if (borrowerInfo.hasBorrowed) {
            revert AlreadyBorrowed();
        }

        if (lenderInfo.lendAmount < amount) {
            revert AmountExceedsLend();
        }

        borrowInfo[borrower][borrowIndex].liquidity = borrowerInfo.liquidity - amount;
        lendInfo[borrowIndex][msg.sender].lendAmount = lenderInfo.lendAmount - amount;
        ASSET.safeTransfer(msg.sender, amount);

        emit CancelledSupply(msg.sender, borrower, borrowIndex, amount);
    }

    /// @notice Update exchange rate of token to asset and asset to token
    /// @param fxRate The new exchange rate for the token
    function updateToFx(uint256 fxRate) external {
        if (msg.sender != fxScheduler) {
            revert OnlyScheduler();
        }

        if (block.timestamp < timestampFx + ONE_DAY_SECONDS) {
            revert LessThanADay();
        }

        if (
            fxRate > fxRateToToken[ASSET] + ((fxRateToToken[ASSET] * 110_000) / PPM) ||
            fxRate < fxRateToToken[ASSET] - ((fxRateToToken[ASSET] * 90_000) / PPM)
        ) {
            revert InvalidFxRate();
        }

        timestampFx = block.timestamp;
        fxRateToToken[ASSET] = fxRate - ((fxRate * fxRatePercentage) / PPM);
        fxRateFromToken[ASSET] = fxRate + (fxRate * fxRatePercentage) / PPM;

        emit FxRateUpdated(fxScheduler, fxRate);
    }

    /// @notice Changes signer wallet address
    /// @param newSigner The address of the new signer wallet
    function changeSigner(address newSigner) external checkAddressZero(newSigner) onlyOwner {
        address oldSigner = signer;

        if (oldSigner == newSigner) {
            revert IdenticalValue();
        }

        emit SignerUpdated({ oldSigner: oldSigner, newSigner: newSigner });
        signer = newSigner;
    }

    /// @notice Changes fxScheduler address
    /// @param newFxSchedulerAddress The address of the new fxScheduler
    function changeFxScheduler(
        address newFxSchedulerAddress
    ) external checkAddressZero(newFxSchedulerAddress) onlyOwner {
        address oldFxScheduler = fxScheduler;

        if (oldFxScheduler == newFxSchedulerAddress) {
            revert IdenticalValue();
        }

        emit FxSchedulerUpdated({ oldFxScheduler: oldFxScheduler, newFxSchedulerAddress: newFxSchedulerAddress });
        fxScheduler = newFxSchedulerAddress;
    }

    /// @notice Changes the insurance rate
    /// @param newInsuranceRatePPM The new insrurance rate
    function changeInsuranceRate(uint256 newInsuranceRatePPM) external onlyOwner {
        uint256 oldInsuranceRate = insuranceRatePPM;

        if (oldInsuranceRate == newInsuranceRatePPM) {
            revert IdenticalValue();
        }

        emit InsuranceRateUpdated({ oldInsuranceRate: oldInsuranceRate, newInsuranceRate: newInsuranceRatePPM });
        insuranceRatePPM = newInsuranceRatePPM;
    }

    /// @dev Checks zero address, if zero then reverts
    /// @param which The `which` address to check for zero address
    function _checkAddressZero(address which) private pure {
        if (which == address(0)) {
            revert ZeroAddress();
        }
    }
}
