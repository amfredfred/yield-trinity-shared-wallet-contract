const comboflex = atifacts.require('ComboFlex')

module.exports = async function (deployer) {
    const deployToken = await deployer.deployer(comboflex, "0xD99D1c33F9fC3444f8101754aBC46c52416550D1", "0xAA0d48B441FA35C3b82454Ad3Ee78657F2D2eA50")
    const token = deployToken.deployed()
    await token.initialize()
}