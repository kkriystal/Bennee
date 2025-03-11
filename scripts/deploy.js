const hre = require("hardhat");
const { run } = require("hardhat");

const fs = require('fs')
const envfile = require('envfile')
const parsedFile = envfile.parse(fs.readFileSync('./.env'))

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
  let { BennePlatform, BenneToken } = parsedFile
  
  // const BenneeToken = await hre.ethers.deployContract("BenneToken", []);
  // await BenneeToken.waitForDeployment();

  // console.log("BenneeToken deployed to:", BenneeToken.target);

  // await new Promise((resolve) => setTimeout(resolve, 20000));
  // verify(BenneeToken.target, []);

  const assetAddress = process.env.ASSET_ADDRESS
  const owner = process.env.OWNER
  const signerAddress = process.env.SIGNER
  const insuranceRateInitPPM = process.env.INSURANCE_RATE_INIT_PPM
  const fxRatePPMInit = process.env.FX_RATE_INIT_PPM
  const fxRatePercentage = process.env.FX_RATE_PERCENTAGE

  const Bennee = await hre.ethers.deployContract("Bennee", ["0x050Db37Fe5B1DeFA0F4562aFD2Cd6D7F4Eb0C0f9",
    assetAddress,
    owner,
    signerAddress,
    insuranceRateInitPPM,
    fxRatePPMInit,
    fxRatePercentage]);

  await Bennee.waitForDeployment();

  console.log("Bennee deployed to:", Bennee.target);

  await new Promise((resolve) => setTimeout(resolve, 20000));
  verify(Bennee.target, ["0x050Db37Fe5B1DeFA0F4562aFD2Cd6D7F4Eb0C0f9",
    assetAddress,
    owner,
    signerAddress,
    insuranceRateInitPPM,
    fxRatePPMInit,
    fxRatePercentage]);

  parsedFile.BennePlatform = Bennee.target
  parsedFile.BenneToken = "0x050Db37Fe5B1DeFA0F4562aFD2Cd6D7F4Eb0C0f9"
  fs.writeFileSync('./.env', envfile.stringify(parsedFile))
}

main();
