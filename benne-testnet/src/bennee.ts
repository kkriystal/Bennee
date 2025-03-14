import { BigDecimal, BigInt, store } from "@graphprotocol/graph-ts"
import {
  Borrowed as BorrowedEvent,
  CancelledRequest as CancelledRequestEvent,
  CancelledSupply as CancelledSupplyEvent,
  DefaultWithdraw as DefaultWithdrawEvent,
  FxRateUpdated as FxRateUpdatedEvent,
  FxSchedulerUpdated as FxSchedulerUpdatedEvent,
  OwnershipTransferStarted as OwnershipTransferStartedEvent,
  OwnershipTransferred as OwnershipTransferredEvent,
  Repaid as RepaidEvent,
  Requested as RequestedEvent,
  SignerUpdated as SignerUpdatedEvent,
  Supplied as SuppliedEvent,
  Withdraw as WithdrawEvent
} from "../generated/Bennee/Bennee"
import {
  Borrowed,
  CancelledRequest,
  CancelledSupply,
  DefaultWithdraw,
  FxRateUpdated,
  FxSchedulerUpdated,
  OwnershipTransferStarted,
  OwnershipTransferred,
  Repaid,
  Requested,
  SignerUpdated,
  Supplied,
  Withdraw,
  LenderInfo,
  BorrowerInfo,
} from "../generated/schema"

// const 1000000 = 1000000;

export function handleBorrowed(event: BorrowedEvent): void {
  let entity = new Borrowed(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.by = event.params.by
  entity.borrowIndex = event.params.borrowIndex
  entity.endTime = event.params.endTime
  entity.mintedAmount = event.params.mintedAmount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()

  let _id = event.params.borrowIndex.toString()
  let requestedEntity = Requested.load(_id)

  let __id = event.params.by.toHexString()
  let bI = BorrowerInfo.load(__id);

  if (!bI) {
    bI = new BorrowerInfo(__id);
    if (requestedEntity) {
      requestedEntity.hasBorrowed = true;
      bI.by = event.params.by
      bI.totalBorrow = requestedEntity.amount
      bI.totalBorrowWithInterest = requestedEntity.amountWithInterest
      bI.interestPaid = BigInt.fromI32(0)
      bI.apy = requestedEntity.interestRate
      bI.totalRepaid = BigInt.fromI32(0)
      bI.totalInterestRepaid = BigInt.fromI32(0)
      requestedEntity.save()
    }
    bI.save()
  } else {
    if (requestedEntity) {
      requestedEntity.hasBorrowed = true;
      bI.by = event.params.by
      bI.totalBorrow = bI.totalBorrow.plus(requestedEntity.amount)
      bI.totalBorrowWithInterest = bI.totalBorrowWithInterest.plus(requestedEntity.amountWithInterest)
      bI.apy = bI.apy.plus(requestedEntity.interestRate).div(BigInt.fromI32(2))
      requestedEntity.save()
    }
    bI.save()
  }
}

export function handleRepaid(event: RepaidEvent): void {
  let entity = new Repaid(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.by = event.params.by
  entity.borrowerIndex = event.params.borrowerIndex
  entity.repayAmount = event.params.repayAmount
  entity.burnAmount = event.params.burnAmount
  entity.lastRepayTime = event.params.lastRepayTime
  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()

  let __id = event.params.by.toHexString()
  let bI = BorrowerInfo.load(__id);

  if (bI) {
    bI.totalRepaid = bI.totalRepaid.plus(event.params.repayAmount)
    bI.totalInterestRepaid = (bI.totalRepaid.times(bI.apy)).div(BigInt.fromI32(1000000))
    bI.save()
  }
}

export function handleCancelledSupply(event: CancelledSupplyEvent): void {
  let entity = new CancelledSupply(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.lender = event.params.lender
  entity.borrowIndex = event.params.borrowIndex
  entity.cancelAmount = event.params.cancelAmount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()

  let _id = event.params.borrowIndex.toString()
  let requestedEntity = Requested.load(_id)
  if (requestedEntity) {
    requestedEntity.liquidity = requestedEntity.liquidity.minus(event.params.cancelAmount);
    requestedEntity.liquidityPercentage = (requestedEntity.liquidity.toBigDecimal().times(BigDecimal.fromString('100'))).div(requestedEntity.amount.toBigDecimal())
    requestedEntity.save()
  }

}

export function handleFxRateUpdated(event: FxRateUpdatedEvent): void {
  let entity = new FxRateUpdated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.scheduler = event.params.scheduler
  entity.fxRate = event.params.fxRate

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleFxSchedulerUpdated(event: FxSchedulerUpdatedEvent): void {
  let entity = new FxSchedulerUpdated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.oldFxScheduler = event.params.oldFxScheduler
  entity.newFxSchedulerAddress = event.params.newFxSchedulerAddress

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleOwnershipTransferStarted(
  event: OwnershipTransferStartedEvent
): void {
  let entity = new OwnershipTransferStarted(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.previousOwner = event.params.previousOwner
  entity.newOwner = event.params.newOwner

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleOwnershipTransferred(
  event: OwnershipTransferredEvent
): void {
  let entity = new OwnershipTransferred(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.previousOwner = event.params.previousOwner
  entity.newOwner = event.params.newOwner

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleRequested(event: RequestedEvent): void {
  let entity = new Requested(
    event.params.index.toString()
  )
  entity.user = event.params.user
  entity.index = event.params.index
  entity.amount = event.params.amount
  entity.tenure = event.params.tenure
  entity.amountWithInterest = event.params.amountWithInterest
  entity.interestRate = event.params.interestRate
  entity.repayAmountPerWindow = event.params.repayAmountPerWindow
  entity.repaymentWIndow = event.params.repaymentWIndow
  entity.liquidity = BigInt.fromI32(0)
  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash
  entity.hasBorrowed = false;
  entity.liquidityPercentage = BigDecimal.fromString('0')
  entity.save()
}

export function handleCancelledRequest(event: CancelledRequestEvent): void {
  let entity = new CancelledRequest(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.by = event.params.by
  entity.borrowIndex = event.params.borrowIndex

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()

  let _id = event.params.borrowIndex.toString()
  store.remove('Requested', _id);

}

export function handleSignerUpdated(event: SignerUpdatedEvent): void {
  let entity = new SignerUpdated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.oldSigner = event.params.oldSigner
  entity.newSigner = event.params.newSigner

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleSupplied(event: SuppliedEvent): void {
  let entity = new Supplied(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.lender = event.params.lender
  entity.lendAmount = event.params.lendAmount
  entity.borrowIndex = event.params.borrowIndex
  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  let _id = event.params.borrowIndex.toString()

  let requestedEntity = Requested.load(_id)
  if (requestedEntity) {
    requestedEntity.liquidity = requestedEntity.liquidity.plus(event.params.lendAmount)
    requestedEntity.liquidityPercentage = (requestedEntity.liquidity.toBigDecimal().times(BigDecimal.fromString('100'))).div(requestedEntity.amount.toBigDecimal())
    entity.borrower = requestedEntity.user;
    requestedEntity.save()
  }

  let __id = event.params.lender.toHexString()
  let lenderInfo = LenderInfo.load(__id);

  if (!lenderInfo) {
    let lenderInfo = new LenderInfo(__id);
    lenderInfo.by = event.params.lender
    lenderInfo.totalLend = event.params.lendAmount
    lenderInfo.withdrawAmount = BigInt.fromI32(0)
    lenderInfo.defaultAmount = BigInt.fromI32(0)

    if (requestedEntity) {
      lenderInfo.apy = requestedEntity.interestRate.toBigDecimal()
      requestedEntity.save()
    }

    lenderInfo.interestEarned = BigDecimal.fromString('0')
    lenderInfo.save()
  } else {
    lenderInfo.by = event.params.lender


    if (requestedEntity) {
      lenderInfo.apy = (lenderInfo.apy.plus(requestedEntity.interestRate.toBigDecimal())).div(BigDecimal.fromString("2"))
      requestedEntity.save()
    }

    lenderInfo.totalLend = lenderInfo.totalLend.plus(event.params.lendAmount)
    lenderInfo.save()
  }

  entity.save()
}


export function handleWithdraw(event: WithdrawEvent): void {
  let entity = new Withdraw(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.by = event.params.by
  entity.borrowIndex = event.params.borrowIndex
  entity.amount = event.params.amount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()

  let __id = event.params.by.toHexString()
  let lenderInfo = LenderInfo.load(__id);

  if (lenderInfo) {
    lenderInfo.by = event.params.by
    lenderInfo.withdrawAmount = lenderInfo.withdrawAmount.plus(event.params.amount)
    lenderInfo.interestEarned = lenderInfo.withdrawAmount.toBigDecimal().times(lenderInfo.apy).div(BigDecimal.fromString('1000000'))
    lenderInfo.save()
  }
}

export function handleDefaultWithdraw(event: DefaultWithdrawEvent): void {
  let entity = new DefaultWithdraw(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.by = event.params.by
  entity.borrowIndex = event.params.borrowIndex
  entity.amount = event.params.amount
  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()

  let __id = event.params.by.toHexString()
  let lenderInfo = LenderInfo.load(__id);

  if (lenderInfo) {

    lenderInfo.by = event.params.by
    lenderInfo.withdrawAmount = lenderInfo.withdrawAmount.plus(event.params.amount)
    lenderInfo.defaultAmount = lenderInfo.defaultAmount.plus(event.params.amount)

    lenderInfo.interestEarned = lenderInfo.withdrawAmount.toBigDecimal().times(lenderInfo.apy).div(BigDecimal.fromString('1000000'))
    lenderInfo.save()
  }
}
