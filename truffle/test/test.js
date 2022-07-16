let Main = artifacts.require('./Main.sol');
let Session = artifacts.require('./Session.sol');


let mainInstance;
let mainAddress;
let sessionInstance;
let sessionAddress;

contract('Contracts', function(accounts) {
    describe('Contract deployment', function() {
        it('Main Contract deployment', function() {        
            return Main.deployed({from: accounts[0]}).then(function(instance) {
            //We save the instance in a global variable and all smart contract functions are called using this
                mainInstance = instance;   
                mainAddress = instance.address;
                assert(mainInstance !== undefined, 'Main contract should be defined');
            });       
        });

        it('Session Contract deployment', function() {       
            return Session.new(mainAddress, "Laptop", "Laptop LENOVO T460s", ["http://localhost:8080/ipfs/QmewTNKfCk7yjrVPsWoCpmidKn5x7JV7Lmv6K68BDtqQuP"], {from: accounts[0]}).then(function(instance) {
            //We save the instance in a global variable and all smart contract functions are called using this
                sessionInstance = instance;   
                sessionAddress = instance.address;
                assert(sessionInstance !== undefined, 'Session contract should be defined');
            });       
        });

        it('View all pricing session', function() {       
            return Session.new(mainAddress, "Laptop", "Laptop LENOVO T460s", ["http://localhost:8080/ipfs/QmewTNKfCk7yjrVPsWoCpmidKn5x7JV7Lmv6K68BDtqQuP"], {from: accounts[0]}).then(function(instance) {
            //We save the instance in a global variable and all smart contract functions are called using this
                sessionInstance = instance;   
                sessionAddress = instance.address;
                assert(sessionInstance !== undefined, 'Session contract should be defined');
            });       
        });
    });

});


contract('Session', function(accounts) {
 //   console.log(mainInstance, "a");
  //accounts[0] is the default account

//   describe('Session Contract deployment', function() {

//     it('Session Contract deployment', function() {

//       //Fetching the contract instance of our smart contract

//       return Auction.deployed().then(function(instance) {

//         //We save the instance in a global variable and all smart contract functions are called using this

//         auctionInstance = instance;

//         assert(

//           auctionInstance !== undefined,

//           'Auction contract should be defined'

//         );

//       });

//     });

//     it('Initial rule with corrected startingPrice and minimumStep', function() {

//       //Fetching the rule of Auction

//       return auctionInstance.rule().then(function(rule) {

//         //We save the instance in a global variable and all smart contract functions are called using this

//         assert(rule !== undefined, 'Rule should be defined');



//         assert.equal(rule.startingPrice, 50, 'Starting price should be 50');

//         assert.equal(rule.minimumStep, 5, 'Minimum step should be 5');

//       });
//     });
  });


  