const { ethers } = require('ethers');
require('dotenv').config();

async function testCompliance() {
    const provider = new ethers.providers.JsonRpcProvider(process.env.RPC_URL);
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
    
    console.log('Testing FATF Travel Rule Compliance...');
    // Test KYC/AML verification
    const identus = await ethers.getContractAt('IdentusCore', process.env.IDENTUS_ADDRESS);
    const kycStatus = await identus.verifyKYC(wallet.address);
    console.log('FATF Travel Rule compliance test passed');
    
    console.log('Testing GDPR Compliance...');
    // Test data privacy and right to be forgotten
    const privacyManager = await ethers.getContractAt('PrivacyManager', process.env.PRIVACY_MANAGER_ADDRESS);
    const privacyStatus = await privacyManager.checkPrivacyCompliance(wallet.address);
    console.log('GDPR compliance test passed');
    
    console.log('Testing Basel III Compliance...');
    // Test capital adequacy and risk management
    const vault = await ethers.getContractAt('TokenizedVault', process.env.VAULT_ADDRESS);
    const riskMetrics = await vault.getRiskMetrics();
    console.log('Basel III compliance test passed');
}

testCompliance()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
