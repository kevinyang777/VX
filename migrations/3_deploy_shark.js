var shark = artifacts.require("./contracts/SharkOutlawSquad.sol");

module.exports = function(deployer) {
	deployer.deploy(shark);
};