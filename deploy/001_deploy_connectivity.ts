import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  await deploy("ConnectivityVerifier", {
    from: deployer,
    args: [],
    log: true,
    autoMine: true,
  });

  const connectivityVerifierAddress = await ethers.getContract(
    "ConnectivityVerifier"
  );

  await deploy("Connectivity", {
    from: deployer,
    args: [connectivityVerifierAddress.address],
    log: true,
    autoMine: true,
  });
};

export default func;
func.tags = ["testbed", "_connectivity"];
