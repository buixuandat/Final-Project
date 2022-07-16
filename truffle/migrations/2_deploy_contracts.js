const Main = artifacts.require('Main');
const Session = artifacts.require('Session');

module.exports = function(deployer) {
  deployer.deploy(Main);
};
