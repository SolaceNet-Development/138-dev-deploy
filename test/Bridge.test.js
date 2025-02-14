const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("Bridge Contract", function () {
    let Bridge, bridge, Oracle, oracle, owner, addr1, addr2;

    async function deployBridgeFixture() {
        const [owner, addr1, addr2] = await ethers.getSigners();
        const Oracle = await ethers.getContractFactory("contracts/core/Oracle.sol:Oracle");
        const oracle = await Oracle.deploy();
        await oracle.waitForDeployment();
        const Bridge = await ethers.getContractFactory("contracts/core/Bridge.sol:Bridge");
        const bridge = await Bridge.deploy(await oracle.getAddress(), 3);
        await bridge.waitForDeployment();
        return { bridge, oracle, owner, addr1, addr2 };
    }

    beforeEach(async function () {
        ({ bridge, oracle, owner, addr1, addr2 } = await loadFixture(deployBridgeFixture));
    });

    it("Should set the right admin", async function () {
        const DEFAULT_ADMIN_ROLE = await bridge.DEFAULT_ADMIN_ROLE();
        expect(await bridge.hasRole(DEFAULT_ADMIN_ROLE, owner.address)).to.be.true;
    });

    it("Should add a validator", async function () {
        await bridge.addValidator(addr1.address);
        const VALIDATOR_ROLE = await bridge.VALIDATOR_ROLE();
        expect(await bridge.hasRole(VALIDATOR_ROLE, addr1.address)).to.be.true;
    });

    it("Should remove a validator", async function () {
        await bridge.addValidator(addr1.address);
        await bridge.removeValidator(addr1.address);
        const VALIDATOR_ROLE = await bridge.VALIDATOR_ROLE();
        expect(await bridge.hasRole(VALIDATOR_ROLE, addr1.address)).to.be.false;
    });

    describe("Transfer validation", function() {
        it("Should validate transfer with sufficient valid signatures", async function() {
            const [from, to, amount] = [
                ethers.zeroPadValue(addr1.address, 32),
                ethers.zeroPadValue(addr2.address, 32),
                ethers.parseEther("1.0")
            ];
            
            const message = ethers.solidityPackedKeccak256(
                ["bytes32", "bytes32", "uint256"],
                [from, to, amount]
            );

            // Add validators
            await bridge.addValidator(addr1.address);
            await bridge.addValidator(addr2.address);

            // Get signatures
            const signatures = [
                await owner.signMessage(ethers.getBytes(message)),
                await addr1.signMessage(ethers.getBytes(message)),
                await addr2.signMessage(ethers.getBytes(message))
            ];

            await expect(bridge.validateTransfer(from, to, amount, signatures))
                .to.emit(bridge, "Transfer")
                .withArgs(from, to, amount);
        });
    });

    describe("Transfer limits and pausing", function() {
        it("Should enforce transfer limits", async function() {
            const to = ethers.zeroPadValue(addr1.address, 32);
            const overLimit = ethers.parseEther("1001");
            
            await expect(bridge.transfer(to, overLimit))
                .to.be.revertedWithCustomError(bridge, "TransferLimitExceeded");
        });

        it("Should pause and unpause transfers", async function() {
            const to = ethers.zeroPadValue(addr1.address, 32);
            const amount = ethers.parseEther("1.0");

            await bridge.pause();
            await expect(bridge.transfer(to, amount))
                .to.be.revertedWithCustomError(bridge, "TransferPaused");

            await bridge.unpause();
            await expect(bridge.transfer(to, amount))
                .to.emit(bridge, "Transfer");
        });

        it("Should prevent duplicate transfer processing", async function() {
            const [from, to, amount] = [
                ethers.zeroPadValue(addr1.address, 32),
                ethers.zeroPadValue(addr2.address, 32),
                ethers.parseEther("1.0")
            ];
            
            const message = ethers.solidityPackedKeccak256(
                ["bytes32", "bytes32", "uint256"],
                [from, to, amount]
            );

            await bridge.addValidator(addr1.address);
            await bridge.addValidator(addr2.address);

            const signatures = [
                await owner.signMessage(ethers.getBytes(message)),
                await addr1.signMessage(ethers.getBytes(message)),
                await addr2.signMessage(ethers.getBytes(message))
            ];
            
            await expect(bridge.validateTransfer(from, to, amount, signatures))
                .to.emit(bridge, "Transfer");
            
            await expect(bridge.validateTransfer(from, to, amount, signatures))
                .to.be.revertedWithCustomError(bridge, "TransferAlreadyProcessed");
        });
    });

    describe("Token support and batch operations", function() {
        let mockToken;
        
        beforeEach(async function() {
            const MockToken = await ethers.getContractFactory("contracts/mocks/MockERC20.sol:MockERC20");
            mockToken = await MockToken.deploy("Mock", "MCK");
            await mockToken.waitForDeployment();
        });

        it("Should manage supported tokens", async function() {
            await bridge.addSupportedToken(mockToken.address);
            expect(await bridge.supportedTokens(mockToken.address)).to.be.true;
            
            await bridge.removeSupportedToken(mockToken.address);
            expect(await bridge.supportedTokens(mockToken.address)).to.be.false;
        });

        it("Should process batch transfers", async function() {
            const froms = [
                ethers.zeroPadValue(addr1.address, 32),
                ethers.zeroPadValue(addr2.address, 32)
            ];
            const tos = [
                ethers.zeroPadValue(addr2.address, 32),
                ethers.zeroPadValue(addr1.address, 32)
            ];
            const amounts = [
                ethers.parseEther("1.0"),
                ethers.parseEther("2.0")
            ];
            
            // Setup signatures for both transfers
            // ... Test implementation ...
        });

        it("Should handle emergency mode correctly", async function() {
            await bridge.enableEmergencyMode();
            expect(await bridge.emergencyMode()).to.be.true;
            
            await expect(bridge.disableEmergencyMode())
                .to.be.revertedWithCustomError(bridge, "EmergencyModeLocked");
                
            // Advance time by 24 hours
            await ethers.provider.send("evm_increaseTime", [24 * 60 * 60]);
            await ethers.provider.send("evm_mine");
            
            await bridge.disableEmergencyMode();
            expect(await bridge.emergencyMode()).to.be.false;
        });
    });

    describe("Fee management", function() {
        it("Should collect fees on transfer", async function() {
            const to = ethers.zeroPadValue(addr1.address, 32);
            const amount = ethers.parseEther("1.0");
            const fee = await bridge.fee();
            
            await expect(bridge.transfer(to, amount, { value: fee }))
                .to.emit(bridge, "Transfer");
                
            expect(await bridge.collectedFees(ethers.ZeroAddress))
                .to.equal(fee);
        });

        it("Should withdraw collected fees", async function() {
            const to = ethers.zeroPadValue(addr1.address, 32);
            const fee = await bridge.fee();
            
            await bridge.transfer(to, ethers.parseEther("1.0"), { value: fee });
            
            const beforeBalance = await ethers.provider.getBalance(addr2.address);
            await bridge.withdrawFees(ethers.ZeroAddress, addr2.address);
            
            const afterBalance = await ethers.provider.getBalance(addr2.address);
            expect(afterBalance - beforeBalance).to.equal(fee);
        });

        it("Should track nonces correctly", async function() {
            const to = ethers.zeroPadValue(addr1.address, 32);
            const fee = await bridge.fee();
            
            await bridge.transfer(to, ethers.parseEther("1.0"), { value: fee });
            expect(await bridge.nonces(owner.address)).to.equal(1);
            
            await bridge.transfer(to, ethers.parseEther("2.0"), { value: fee });
            expect(await bridge.nonces(owner.address)).to.equal(2);
        });
    });

    describe("Role-based access control", function() {
        it("Should grant and revoke roles correctly", async function() {
            const VALIDATOR_ROLE = await bridge.VALIDATOR_ROLE();
            expect(await bridge.hasRole(VALIDATOR_ROLE, owner.address)).to.be.true;
            
            await bridge.grantRole(VALIDATOR_ROLE, addr1.address);
            expect(await bridge.hasRole(VALIDATOR_ROLE, addr1.address)).to.be.true;
            
            await bridge.revokeRole(VALIDATOR_ROLE, addr1.address);
            expect(await bridge.hasRole(VALIDATOR_ROLE, addr1.address)).to.be.false;
        });

        it("Should cache and expire validations", async function() {
            const messageHash = ethers.id("test");
            const validator = addr1.address;
            
            await bridge.cacheValidation(messageHash, validator);
            expect(await bridge.isValidationCached(messageHash, validator)).to.be.true;
            
            // Advance time past cache expiration
            await ethers.provider.send("evm_increaseTime", [3600 + 1]);
            await ethers.provider.send("evm_mine");
            
            expect(await bridge.isValidationCached(messageHash, validator)).to.be.false;
        });
    });

    describe("Gas optimization tests", function() {
        it("Should execute batch transfers within gas limits", async function() {
            const { bridge } = await loadFixture(deployBridgeFixture);
            // Add gas usage tests
        });
    });

    describe("Error handling", function() {
        it("Should handle failed transfers gracefully", async function() {
            // Add error handling tests
        });
    });

    // Add more tests as necessary
});
