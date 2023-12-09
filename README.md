# Foundry Safe{Core} Protocol 

*A [Foundry](https://getfoundry.sh/) template for testing and deploying [Safe{Core} Protocol Plugins](https://docs.safe.global/safe-core-protocol/plugins). Automates setting up a manager, register & Safe; plus enables them so you can focus on writing the plugin logic.*

**This template is meant for testnet & quick experimentation only. You should write and audit your own deployment and testing scripts in production**

Shipped by [Panda Account Abstraction Initiative](https://github.com/WillSchiller/safe-plugin-foundry-template) as part of [100.builders](https://100.builders/) Program.

## Pre-requisites

* Install Foundry ```curl -L https://foundry.paradigm.xyz | bash```
* clone this repo ```git clone git@github.com:WillSchiller/safe-plugin-foundry-template.git```
* Run ```foundryup``` to update Foundry installation


## Usage

### Writing plugin

The plugin contract can be found in `src/plugin.sol`. It inherits from `src.base.sol` which provides the basic functionality to set metadata but the plugin logic itself is not implemented.

### Testing plugin

The test file provides a `setUp` function which deploys a Safe, a Manager and a Register. It then enables manager module on the safe and adds the plugin on the Manager and Register so you can start testing your plugin logic without worrying about the deployment & enabling. run the tests with ```forge test -vvvv```.

### Deploying the plugin

The deployment script can be found in `script/Deploy.s.sol`. The functionality is the same as the test `setUp` only it will deploy the contracts to the network you specify in the `.env` file. Run the script with ```source .env && forge script script/Deploy.s.sol:Deploy -vvvv --fork-url $GOERLI_RPC_URL --broadcast```.


### Depoyed contract info:


== Logs ==
  Deploy.s.sol: run================================- 
  DeployContracts.s.sol: run===================
  SafeProtocolRegistry address= 0xb0b8c7cCc64be9aa9B5712BBEc5a5BD0a3213059
  SafeProtocolManager address= 0xB5A92EB54CD44C87875Ec8d4e166708ec6CCa61F
  WagBox address= 0x6169d1F0feF34fF99A92c03134aa57eaf762FeE1
  MockPointProtocol address= 0x45FF4CCF804572B3bA17081348abf871D8A2e280
  PointCardPlugin address= 0x091578BAe1A95c0322441509CCA99fC3248F9A5A
  DeployContracts.s.sol: run=================== end
  Deploy.s.sol: run================================- END



source .env && forge script script/Deploy.s.sol:Deploy --rpc-url $GOERLI_RPC_URL  --verifier-url https://mumbai.polygonscan.com/api --broadcast --verify -vvvv

source .env && forge script script/Deploy.s.sol:Deploy --rpc-url $GOERLI_RPC_URL --broadcast -vvvv