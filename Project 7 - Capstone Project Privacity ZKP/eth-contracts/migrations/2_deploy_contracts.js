// migrating the appropriate contracts
var Verifier = artifacts.require("./Verifier.sol");
var CapstoneERC721Token = artifacts.require("./OpenSeaToken721.sol");
var SolnSquareVerifier = artifacts.require("./SolnSquareVerifier.sol");

module.exports = async (deployer) => {

  await deployer.deploy(Verifier);
  await deployer.deploy(CapstoneERC721Token, "Open-Sea", "OPS");
  await deployer.deploy(SolnSquareVerifier, Verifier.address, "Open-Sea", "OPS");
};