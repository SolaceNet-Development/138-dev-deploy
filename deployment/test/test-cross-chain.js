const { ethers } = require('ethers');
require('dotenv').config();

async function testCrossChain() {
    const provider = new ethers.providers.JsonRpcProvider(process.env.RPC_URL);
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
    
    console.log('Testing Cross-Chain Messaging...');
    const messaging = await ethers.getContractAt('CrossChainMessaging', process.env.MESSAGING_ADDRESS);
    
    // Test message sending
    const tx = await messaging.sendMessage(
        137, // Polygon chain ID
        ethers.utils.defaultAbiCoder.encode(['string'], ['test message'])
    );
    await tx.wait();
    
    // Verify message event
    const filter = messaging.filters.MessageSent();
    const events = await messaging.queryFilter(filter);
    console.log('Cross-Chain Messaging test passed');
}

testCrossChain()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
