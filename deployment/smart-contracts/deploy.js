const { ethers } = require('ethers');
require('dotenv').config();

async function main() {
    const provider = new ethers.providers.JsonRpcProvider(process.env.RPC_URL);
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
    
    console.log('Deploying contracts with account:', wallet.address);
    
    // Deploy Multicall3
    const Multicall3 = await ethers.getContractFactory('Multicall3', wallet);
    const multicall = await Multicall3.deploy();
    await multicall.deployed();
    console.log('Multicall3 deployed to:', multicall.address);
    
    // Deploy DiamondProxy
    const DiamondProxy = await ethers.getContractFactory('DiamondProxy', wallet);
    const diamond = await DiamondProxy.deploy(wallet.address, wallet.address);
    await diamond.deployed();
    console.log('DiamondProxy deployed to:', diamond.address);
    
    // Deploy TokenizedVault
    const TokenizedVault = await ethers.getContractFactory('TokenizedVault', wallet);
    const vault = await TokenizedVault.deploy(process.env.ASSET_TOKEN_ADDRESS);
    await vault.deployed();
    console.log('TokenizedVault deployed to:', vault.address);
    
    // Deploy CrossChainMessaging
    const CrossChainMessaging = await ethers.getContractFactory('CrossChainMessaging', wallet);
    const messaging = await CrossChainMessaging.deploy();
    await messaging.deployed();
    console.log('CrossChainMessaging deployed to:', messaging.address);
    
    // Verify contracts
    console.log('\nVerifying contracts...');
    await hre.run('verify:verify', {
        address: multicall.address,
        constructorArguments: []
    });
    
    await hre.run('verify:verify', {
        address: diamond.address,
        constructorArguments: [wallet.address, wallet.address]
    });
    
    await hre.run('verify:verify', {
        address: vault.address,
        constructorArguments: [process.env.ASSET_TOKEN_ADDRESS]
    });
    
    await hre.run('verify:verify', {
        address: messaging.address,
        constructorArguments: []
    });
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
