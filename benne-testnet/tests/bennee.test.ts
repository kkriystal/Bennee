import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { Address, BigInt } from "@graphprotocol/graph-ts"
import { Borrowed } from "../generated/schema"
import { Borrowed as BorrowedEvent } from "../generated/Bennee/Bennee"
import { handleBorrowed } from "../src/bennee"
import { createBorrowedEvent } from "./bennee-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let by = Address.fromString("0x0000000000000000000000000000000000000001")
    let borrowIndex = BigInt.fromI32(234)
    let newBorrowedEvent = createBorrowedEvent(by, borrowIndex)
    handleBorrowed(newBorrowedEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("Borrowed created and stored", () => {
    assert.entityCount("Borrowed", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "Borrowed",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "by",
      "0x0000000000000000000000000000000000000001"
    )
    assert.fieldEquals(
      "Borrowed",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "borrowIndex",
      "234"
    )

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  })
})
