import { newMockEvent } from "matchstick-as"
import { ethereum, Address, BigInt } from "@graphprotocol/graph-ts"
import {
  Borrowed,
  CancelledRequest,
  CancelledSupply,
  DefaultWithdraw,
  FxRateUpdated,
  FxSchedulerUpdated,
  InsuranceRateUpdated,
  OwnershipTransferStarted,
  OwnershipTransferred,
  Repaid,
  Requested,
  SignerUpdated,
  Supplied,
  Withdraw
} from "../generated/Bennee/Bennee"

export function createBorrowedEvent(
  by: Address,
  borrowIndex: BigInt,
  endTime: BigInt,
  mintedAmount: BigInt
): Borrowed {
  let borrowedEvent = changetype<Borrowed>(newMockEvent())

  borrowedEvent.parameters = new Array()

  borrowedEvent.parameters.push(
    new ethereum.EventParam("by", ethereum.Value.fromAddress(by))
  )
  borrowedEvent.parameters.push(
    new ethereum.EventParam(
      "borrowIndex",
      ethereum.Value.fromUnsignedBigInt(borrowIndex)
    )
  )
  borrowedEvent.parameters.push(
    new ethereum.EventParam(
      "endTime",
      ethereum.Value.fromUnsignedBigInt(endTime)
    )
  )
  borrowedEvent.parameters.push(
    new ethereum.EventParam(
      "mintedAmount",
      ethereum.Value.fromUnsignedBigInt(mintedAmount)
    )
  )

  return borrowedEvent
}

export function createCancelledRequestEvent(
  by: Address,
  borrowIndex: BigInt
): CancelledRequest {
  let cancelledRequestEvent = changetype<CancelledRequest>(newMockEvent())

  cancelledRequestEvent.parameters = new Array()

  cancelledRequestEvent.parameters.push(
    new ethereum.EventParam("by", ethereum.Value.fromAddress(by))
  )
  cancelledRequestEvent.parameters.push(
    new ethereum.EventParam(
      "borrowIndex",
      ethereum.Value.fromUnsignedBigInt(borrowIndex)
    )
  )

  return cancelledRequestEvent
}

export function createCancelledSupplyEvent(
  lender: Address,
  borrowIndex: BigInt,
  cancelAmount: BigInt
): CancelledSupply {
  let cancelledSupplyEvent = changetype<CancelledSupply>(newMockEvent())

  cancelledSupplyEvent.parameters = new Array()

  cancelledSupplyEvent.parameters.push(
    new ethereum.EventParam("lender", ethereum.Value.fromAddress(lender))
  )
  cancelledSupplyEvent.parameters.push(
    new ethereum.EventParam(
      "borrowIndex",
      ethereum.Value.fromUnsignedBigInt(borrowIndex)
    )
  )
  cancelledSupplyEvent.parameters.push(
    new ethereum.EventParam(
      "cancelAmount",
      ethereum.Value.fromUnsignedBigInt(cancelAmount)
    )
  )

  return cancelledSupplyEvent
}

export function createDefaultWithdrawEvent(
  by: Address,
  borrowIndex: BigInt,
  amount: BigInt
): DefaultWithdraw {
  let defaultWithdrawEvent = changetype<DefaultWithdraw>(newMockEvent())

  defaultWithdrawEvent.parameters = new Array()

  defaultWithdrawEvent.parameters.push(
    new ethereum.EventParam("by", ethereum.Value.fromAddress(by))
  )
  defaultWithdrawEvent.parameters.push(
    new ethereum.EventParam(
      "borrowIndex",
      ethereum.Value.fromUnsignedBigInt(borrowIndex)
    )
  )
  defaultWithdrawEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )

  return defaultWithdrawEvent
}

export function createFxRateUpdatedEvent(
  scheduler: Address,
  fxRate: BigInt
): FxRateUpdated {
  let fxRateUpdatedEvent = changetype<FxRateUpdated>(newMockEvent())

  fxRateUpdatedEvent.parameters = new Array()

  fxRateUpdatedEvent.parameters.push(
    new ethereum.EventParam("scheduler", ethereum.Value.fromAddress(scheduler))
  )
  fxRateUpdatedEvent.parameters.push(
    new ethereum.EventParam("fxRate", ethereum.Value.fromUnsignedBigInt(fxRate))
  )

  return fxRateUpdatedEvent
}

export function createFxSchedulerUpdatedEvent(
  oldFxScheduler: Address,
  newFxSchedulerAddress: Address
): FxSchedulerUpdated {
  let fxSchedulerUpdatedEvent = changetype<FxSchedulerUpdated>(newMockEvent())

  fxSchedulerUpdatedEvent.parameters = new Array()

  fxSchedulerUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "oldFxScheduler",
      ethereum.Value.fromAddress(oldFxScheduler)
    )
  )
  fxSchedulerUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "newFxSchedulerAddress",
      ethereum.Value.fromAddress(newFxSchedulerAddress)
    )
  )

  return fxSchedulerUpdatedEvent
}

export function createInsuranceRateUpdatedEvent(
  oldInsuranceRate: BigInt,
  newInsuranceRate: BigInt
): InsuranceRateUpdated {
  let insuranceRateUpdatedEvent =
    changetype<InsuranceRateUpdated>(newMockEvent())

  insuranceRateUpdatedEvent.parameters = new Array()

  insuranceRateUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "oldInsuranceRate",
      ethereum.Value.fromUnsignedBigInt(oldInsuranceRate)
    )
  )
  insuranceRateUpdatedEvent.parameters.push(
    new ethereum.EventParam(
      "newInsuranceRate",
      ethereum.Value.fromUnsignedBigInt(newInsuranceRate)
    )
  )

  return insuranceRateUpdatedEvent
}

export function createOwnershipTransferStartedEvent(
  previousOwner: Address,
  newOwner: Address
): OwnershipTransferStarted {
  let ownershipTransferStartedEvent =
    changetype<OwnershipTransferStarted>(newMockEvent())

  ownershipTransferStartedEvent.parameters = new Array()

  ownershipTransferStartedEvent.parameters.push(
    new ethereum.EventParam(
      "previousOwner",
      ethereum.Value.fromAddress(previousOwner)
    )
  )
  ownershipTransferStartedEvent.parameters.push(
    new ethereum.EventParam("newOwner", ethereum.Value.fromAddress(newOwner))
  )

  return ownershipTransferStartedEvent
}

export function createOwnershipTransferredEvent(
  previousOwner: Address,
  newOwner: Address
): OwnershipTransferred {
  let ownershipTransferredEvent =
    changetype<OwnershipTransferred>(newMockEvent())

  ownershipTransferredEvent.parameters = new Array()

  ownershipTransferredEvent.parameters.push(
    new ethereum.EventParam(
      "previousOwner",
      ethereum.Value.fromAddress(previousOwner)
    )
  )
  ownershipTransferredEvent.parameters.push(
    new ethereum.EventParam("newOwner", ethereum.Value.fromAddress(newOwner))
  )

  return ownershipTransferredEvent
}

export function createRepaidEvent(
  borrowerIndex: BigInt,
  param1: BigInt,
  burnAmount: BigInt,
  lastRepayTime: BigInt
): Repaid {
  let repaidEvent = changetype<Repaid>(newMockEvent())

  repaidEvent.parameters = new Array()

  repaidEvent.parameters.push(
    new ethereum.EventParam(
      "borrowerIndex",
      ethereum.Value.fromUnsignedBigInt(borrowerIndex)
    )
  )
  repaidEvent.parameters.push(
    new ethereum.EventParam("param1", ethereum.Value.fromUnsignedBigInt(param1))
  )
  repaidEvent.parameters.push(
    new ethereum.EventParam(
      "burnAmount",
      ethereum.Value.fromUnsignedBigInt(burnAmount)
    )
  )
  repaidEvent.parameters.push(
    new ethereum.EventParam(
      "lastRepayTime",
      ethereum.Value.fromUnsignedBigInt(lastRepayTime)
    )
  )

  return repaidEvent
}

export function createRequestedEvent(
  user: Address,
  index: BigInt,
  amount: BigInt,
  tenure: BigInt,
  amountWithInterest: BigInt,
  interestRate: BigInt,
  repayAmountPerWindow: BigInt,
  repaymentWIndow: BigInt
): Requested {
  let requestedEvent = changetype<Requested>(newMockEvent())

  requestedEvent.parameters = new Array()

  requestedEvent.parameters.push(
    new ethereum.EventParam("user", ethereum.Value.fromAddress(user))
  )
  requestedEvent.parameters.push(
    new ethereum.EventParam("index", ethereum.Value.fromUnsignedBigInt(index))
  )
  requestedEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )
  requestedEvent.parameters.push(
    new ethereum.EventParam("tenure", ethereum.Value.fromUnsignedBigInt(tenure))
  )
  requestedEvent.parameters.push(
    new ethereum.EventParam(
      "amountWithInterest",
      ethereum.Value.fromUnsignedBigInt(amountWithInterest)
    )
  )
  requestedEvent.parameters.push(
    new ethereum.EventParam(
      "interestRate",
      ethereum.Value.fromUnsignedBigInt(interestRate)
    )
  )
  requestedEvent.parameters.push(
    new ethereum.EventParam(
      "repayAmountPerWindow",
      ethereum.Value.fromUnsignedBigInt(repayAmountPerWindow)
    )
  )
  requestedEvent.parameters.push(
    new ethereum.EventParam(
      "repaymentWIndow",
      ethereum.Value.fromUnsignedBigInt(repaymentWIndow)
    )
  )

  return requestedEvent
}

export function createSignerUpdatedEvent(
  oldSigner: Address,
  newSigner: Address
): SignerUpdated {
  let signerUpdatedEvent = changetype<SignerUpdated>(newMockEvent())

  signerUpdatedEvent.parameters = new Array()

  signerUpdatedEvent.parameters.push(
    new ethereum.EventParam("oldSigner", ethereum.Value.fromAddress(oldSigner))
  )
  signerUpdatedEvent.parameters.push(
    new ethereum.EventParam("newSigner", ethereum.Value.fromAddress(newSigner))
  )

  return signerUpdatedEvent
}

export function createSuppliedEvent(
  lender: Address,
  lendAmount: BigInt,
  borrowIndex: BigInt
): Supplied {
  let suppliedEvent = changetype<Supplied>(newMockEvent())

  suppliedEvent.parameters = new Array()

  suppliedEvent.parameters.push(
    new ethereum.EventParam("lender", ethereum.Value.fromAddress(lender))
  )
  suppliedEvent.parameters.push(
    new ethereum.EventParam(
      "lendAmount",
      ethereum.Value.fromUnsignedBigInt(lendAmount)
    )
  )
  suppliedEvent.parameters.push(
    new ethereum.EventParam(
      "borrowIndex",
      ethereum.Value.fromUnsignedBigInt(borrowIndex)
    )
  )

  return suppliedEvent
}

export function createWithdrawEvent(
  by: Address,
  borrowIndex: BigInt,
  amount: BigInt
): Withdraw {
  let withdrawEvent = changetype<Withdraw>(newMockEvent())

  withdrawEvent.parameters = new Array()

  withdrawEvent.parameters.push(
    new ethereum.EventParam("by", ethereum.Value.fromAddress(by))
  )
  withdrawEvent.parameters.push(
    new ethereum.EventParam(
      "borrowIndex",
      ethereum.Value.fromUnsignedBigInt(borrowIndex)
    )
  )
  withdrawEvent.parameters.push(
    new ethereum.EventParam("amount", ethereum.Value.fromUnsignedBigInt(amount))
  )

  return withdrawEvent
}
