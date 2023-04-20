const Discover = artifacts.require('IYieldTrinityDicoverer')
const SharedWallet = artifacts.require('YieldTrinitySharedWallet')

module.exports = async function (deployer) {
    const discover = deployer.deploy(Discover, )
}