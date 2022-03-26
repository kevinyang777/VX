var shark = artifacts.require("./contracts/SharkOutlawSquadPixel.sol");

module.exports = function(deployer) {
	deployer.deploy(shark);
};