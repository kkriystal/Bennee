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
  Withdraw
} from "../generated/schema"

export function handleBorrowed(event: BorrowedEvent): void {
  let entity = new Borrowed(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.by = event.params.by
  entity.borrowIndex = event.params.borrowIndex

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

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
}

export function handleCancelledSupply(event: CancelledSupplyEvent): void {
  let entity = new CancelledSupply(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.lender = event.params.lender
  entity.borrower = event.params.borrower
  entity.borrowIndex = event.params.borrowIndex
  entity.cancelAmount = event.params.cancelAmount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleDefaultWithdraw(event: DefaultWithdrawEvent): void {
  let entity = new DefaultWithdraw(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.by = event.params.by
  entity.borrowIndex = event.params.borrowIndex
  entity.borrower = event.params.borrower
  entity.amount = event.params.amount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
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
  entity.newFxScheduler = event.params.newFxScheduler

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

export function handleRepaid(event: RepaidEvent): void {
  let entity = new Repaid(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.borrower = event.params.borrower
  entity.borrowerIndex = event.params.borrowerIndex
  entity.repayAmount = event.params.repayAmount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleRequested(event: RequestedEvent): void {
  let entity = new Requested(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.user = event.params.user
  entity.index = event.params.index
  entity.amount = event.params.amount
  entity.tenure = event.params.tenure
  entity.interestRate = event.params.interestRate
  entity.repaymentWIndow = event.params.repaymentWIndow

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
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
  entity.borrower = event.params.borrower
  entity.borrowIndex = event.params.borrowIndex

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleWithdraw(event: WithdrawEvent): void {
  let entity = new Withdraw(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.by = event.params.by
  entity.borrowIndex = event.params.borrowIndex
  entity.borrower = event.params.borrower
  entity.amount = event.params.amount

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}
