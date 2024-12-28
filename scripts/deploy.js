const hre = require("hardhat");
const { run } = require("hardhat");
async function verify(address, constructorArguments) {
  console.log(
    `verify  ${address} with arguments ${constructorArguments.join(",")}`
  );
  await run("verify:verify", {
    address,
    constructorArguments,
  });
}

async function main() {
  const benneeAddress = process.env.BENNE_TOKEN
  const assetAddress = process.env.ASSET_ADDRESS
  const owner = process.env.OWNER
  const signerAddress = process.env.SIGNER
  const insuranceRateInitPPM = process.env.INSURANCE_RATE_INIT_PPM
  const fxRatePPMInit = process.env.FX_RATE_INIT_PPM
  const fxRatePercentage = process.env.FX_RATE_PERCENTAGE

  const Bennee = await hre.ethers.deployContract("Bennee", [benneeAddress,
    assetAddress,
    owner,
    signerAddress,
    insuranceRateInitPPM,
    fxRatePPMInit,
    fxRatePercentage]);
  await Bennee.waitForDeployment();

  console.log("Bennee deployed to:", Bennee.target);

  await new Promise((resolve) => setTimeout(resolve, 20000));
  verify(Bennee.target, [benneeAddress,
    assetAddress,
    owner,
    signerAddress,
    insuranceRateInitPPM,
    fxRatePPMInit,
    fxRatePercentage]);
}
main();
