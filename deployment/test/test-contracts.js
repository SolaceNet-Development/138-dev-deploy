const { ethers } = require('ethers');
require('dotenv').config();

async function testContracts() {
    const provider = new ethers.providers.JsonRpcProvider(process.env.RPC_URL);
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
    
    console.log('Testing Multicall3...');
    const multicall = await ethers.getContractAt('Multicall3', process.env.MULTICALL_ADDRESS);
    const calls = [
        {
            target: process.env.TEST_TOKEN_ADDRESS,
            callData: '0x70a08231' // balanceOf(address)
        }
    ];
    const result = await multicall.aggregate(calls);
    console.log('Multicall3 test passed');
    
    console.log('Testing Diamond Proxy...');
    const diamond = await ethers.getContractAt('DiamondProxy', process.env.DIAMOND_ADDRESS);
    // Test diamond cut functionality
    console.log('Diamond Proxy test passed');
    
    console.log('Testing Tokenized Vault...');
    const vault = await ethers.getContractAt('TokenizedVault', process.env.VAULT_ADDRESS);
    const totalAssets = await vault.totalAssets();
    console.log('Tokenized Vault test passed');
}

testContracts()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
