import XCTest
@testable import Lattice
import UInt256

final class ChainSpecTests: XCTestCase {
    
    
    // MARK: - Basic Properties Tests
    
    func testChainSpecInitialization() {
        let chainSpec = ChainSpec(
            maxNumberOfTransactionsPerBlock: 1000,
            maxStateGrowth: 500_000,
            premine: 21_000,
            targetBlockTime: 600_000,  // 10 minutes in milliseconds
            initialRewardExponent: 20,
            transactionFilters: ["filter1", "filter2"]
        )
        
        XCTAssertEqual(chainSpec.maxNumberOfTransactionsPerBlock, 1000)
        XCTAssertEqual(chainSpec.maxStateGrowth, 500_000)
        XCTAssertEqual(chainSpec.premine, 21_000)
        XCTAssertEqual(chainSpec.targetBlockTime, 600_000)
        XCTAssertEqual(chainSpec.initialRewardExponent, 20)
        XCTAssertEqual(ChainSpec.maxDifficultyChange, 2)
        XCTAssertEqual(chainSpec.transactionFilters.count, 2)
    }
    
    func testValidation() {
        let validSpec = ChainSpec(maxNumberOfTransactionsPerBlock: 1000, maxStateGrowth: 1000, premine: 100, targetBlockTime: 10_000, initialRewardExponent: 10)
        XCTAssertTrue(validSpec.isValid)
        
        let invalidTransactionCount = ChainSpec(maxNumberOfTransactionsPerBlock: 0, maxStateGrowth: 1000, premine: 100, targetBlockTime: 10_000, initialRewardExponent: 10)
        XCTAssertFalse(invalidTransactionCount.isValid)
        
        let invalidStateGrowth = ChainSpec(maxNumberOfTransactionsPerBlock: 1000, maxStateGrowth: 0, premine: 100, targetBlockTime: 10_000, initialRewardExponent: 10)
        XCTAssertFalse(invalidStateGrowth.isValid)
        
        let invalidBlockTime = ChainSpec(maxNumberOfTransactionsPerBlock: 1000, maxStateGrowth: 1000, premine: 100, targetBlockTime: 0, initialRewardExponent: 10)
        XCTAssertFalse(invalidBlockTime.isValid)
        
        let invalidExponent = ChainSpec(maxNumberOfTransactionsPerBlock: 1000, maxStateGrowth: 1000, premine: 100, targetBlockTime: 10_000, initialRewardExponent: 0)
        XCTAssertFalse(invalidExponent.isValid)
        
        let tooLargeExponent = ChainSpec(maxNumberOfTransactionsPerBlock: 1000, maxStateGrowth: 1000, premine: 100, targetBlockTime: 10_000, initialRewardExponent: 64)
        XCTAssertFalse(tooLargeExponent.isValid)
        
        // Test invalid premine (exceeding halving interval)
        // For initialRewardExponent=10, halvingInterval = 2^(64-10) = 2^54
        let testSpec = ChainSpec(maxNumberOfTransactionsPerBlock: 1000, maxStateGrowth: 1000, premine: 100, targetBlockTime: 10_000, initialRewardExponent: 10)
        let halvingInterval = testSpec.halvingInterval  // 2^54
        
        let invalidPremine = ChainSpec(maxNumberOfTransactionsPerBlock: 1000, maxStateGrowth: 1000, premine: halvingInterval, targetBlockTime: 10_000, initialRewardExponent: 10)
        XCTAssertFalse(invalidPremine.isValid)
        
        // Test valid premine (just under halving interval)  
        let validPremine = ChainSpec(maxNumberOfTransactionsPerBlock: 1000, maxStateGrowth: 1000, premine: halvingInterval - 1, targetBlockTime: 10_000, initialRewardExponent: 10)
        XCTAssertTrue(validPremine.isValid)
        
        // maxDifficultyChange is now a static property, so no need to test invalid values
    }
    
    // MARK: - Reward Calculation Tests
    
    func testInitialReward() {
        let chainSpec = ChainSpec(maxNumberOfTransactionsPerBlock: 1000, maxStateGrowth: 1000, premine: 0, targetBlockTime: 10_000, initialRewardExponent: 20)
        let expectedReward = UInt64(1) << 20  // 2^20 = 1,048,576
        
        XCTAssertEqual(chainSpec.initialReward, expectedReward)
        XCTAssertEqual(chainSpec.initialReward, 1_048_576)
    }
    
    func testHalvingInterval() {
        let chainSpec = ChainSpec(maxNumberOfTransactionsPerBlock: 1000, maxStateGrowth: 1000, premine: 0, targetBlockTime: 10_000, initialRewardExponent: 20)
        let expectedInterval = UInt64(1) << (64 - 20)  // 2^44
        
        XCTAssertEqual(chainSpec.halvingInterval, expectedInterval)
        
        // Test different reward exponents
        let chainSpec10 = ChainSpec(maxNumberOfTransactionsPerBlock: 1000, maxStateGrowth: 1000, premine: 0, targetBlockTime: 10_000, initialRewardExponent: 10)
        XCTAssertEqual(chainSpec10.halvingInterval, UInt64(1) << (64 - 10))  // 2^54
        
        let chainSpec30 = ChainSpec(maxNumberOfTransactionsPerBlock: 1000, maxStateGrowth: 1000, premine: 0, targetBlockTime: 10_000, initialRewardExponent: 30)
        XCTAssertEqual(chainSpec30.halvingInterval, UInt64(1) << (64 - 30))  // 2^34
    }
    
    func testRewardAtBlock() {
        let chainSpec = ChainSpec(maxNumberOfTransactionsPerBlock: 1000, maxStateGrowth: 1000, premine: 0, targetBlockTime: 10_000, initialRewardExponent: 10)
        let initialReward = chainSpec.initialReward  // 2^10 = 1024
        let halvingInterval = chainSpec.halvingInterval
        
        // Block 0: full reward
        XCTAssertEqual(chainSpec.rewardAtBlock(0), initialReward)
        
        // Block before first halving: full reward
        XCTAssertEqual(chainSpec.rewardAtBlock(halvingInterval - 1), initialReward)
        
        // Block at first halving: half reward
        XCTAssertEqual(chainSpec.rewardAtBlock(halvingInterval), initialReward / 2)
        
        // Block at second halving: quarter reward  
        XCTAssertEqual(chainSpec.rewardAtBlock(halvingInterval * 2), initialReward / 4)
    }
    
    func testRewardCaching() {
        let chainSpec = ChainSpec(maxNumberOfTransactionsPerBlock: 1000, maxStateGrowth: 1000, premine: 0, targetBlockTime: 10_000, initialRewardExponent: 10)
        
        // First call should cache the result
        let reward1 = chainSpec.rewardAtBlock(1000)
        let reward2 = chainSpec.rewardAtBlock(1000)
        
        XCTAssertEqual(reward1, reward2)
        
        // Test with different blocks
        let reward3 = chainSpec.rewardAtBlock(2000)
        XCTAssertNotEqual(reward1, reward3)
    }
    
    func testTotalRewards() {
        let chainSpec = ChainSpec(maxNumberOfTransactionsPerBlock: 1000, maxStateGrowth: 1000, premine: 0, targetBlockTime: 10_000, initialRewardExponent: 10)
        let initialReward = chainSpec.initialReward  // 1024
        let halvingInterval = chainSpec.halvingInterval
        
        // Total rewards for first halving period
        let rewardsFirstPeriod = chainSpec.totalRewards(upToBlock: halvingInterval)
        let expectedFirstPeriod = initialReward * halvingInterval
        XCTAssertEqual(rewardsFirstPeriod, expectedFirstPeriod)
        
        // Total rewards for small number of blocks
        let rewards10Blocks = chainSpec.totalRewards(upToBlock: 10)
        XCTAssertEqual(rewards10Blocks, initialReward * 10)
        
        // Zero blocks should return zero
        XCTAssertEqual(chainSpec.totalRewards(upToBlock: 0), 0)
    }
    
    func testPremineAmount() {
        let chainSpec = ChainSpec(maxNumberOfTransactionsPerBlock: 1000, maxStateGrowth: 1000, premine: 1000, targetBlockTime: 10_000, initialRewardExponent: 10)
        let expectedPremine = chainSpec.totalRewards(upToBlock: 1000)
        
        // Premine represents creators mining blocks 0 to 999 (first 1000 blocks)
        XCTAssertEqual(chainSpec.premineAmount(), expectedPremine)
        XCTAssertEqual(chainSpec.premineAmount(), 1024 * 1000)  // 1024 reward * 1000 blocks
        
        // Verify this equals individual block rewards for blocks 0-999
        let manualSum = (0..<1000).reduce(0) { sum, blockIndex in
            return sum + chainSpec.rewardAtBlock(blockIndex)
        }
        XCTAssertEqual(chainSpec.premineAmount(), manualSum)
    }
    
    func testPremineBlockMiningTimeline() {
        let chainSpec = ChainSpec(maxNumberOfTransactionsPerBlock: 1000, maxStateGrowth: 1000, premine: 5, targetBlockTime: 10_000, initialRewardExponent: 10)
        let initialReward = chainSpec.initialReward
        let halvingInterval = chainSpec.halvingInterval
        
        // Block 0: First public mining block (premine of 5 creates offset)
        // This is treated as block 5 in the halving schedule due to premine offset
        XCTAssertEqual(chainSpec.rewardAtBlock(0), initialReward, "Block 0 (first public block) should have full reward")
        
        // Public mining blocks should have full reward until halving
        for blockIndex in 0..<100 {
            XCTAssertEqual(chainSpec.rewardAtBlock(UInt64(blockIndex)), initialReward, "Public mining block \(blockIndex) should have full reward")
        }
        
        // Premine amount should equal rewards for the 5 premine blocks
        XCTAssertEqual(chainSpec.premineAmount(), initialReward * 5)
        
        // First halving occurs when offsetBlockIndex (blockIndex + premine) reaches halvingInterval
        // So blockIndex = halvingInterval - premine
        let firstHalvingBlock = halvingInterval - 5  // Account for premine offset
        XCTAssertEqual(chainSpec.rewardAtBlock(firstHalvingBlock - 1), initialReward)
        XCTAssertEqual(chainSpec.rewardAtBlock(firstHalvingBlock), initialReward / 2)
    }
    
    func testPremineOffsetInHalving() {
        let chainSpec = ChainSpec(maxNumberOfTransactionsPerBlock: 1000, maxStateGrowth: 1000, premine: 100, targetBlockTime: 10_000, initialRewardExponent: 10)
        let initialReward = chainSpec.initialReward
        let halvingInterval = chainSpec.halvingInterval
        
        // Block 0: First public mining block (offset by premine)
        // offsetBlockIndex = 0 + 100 = 100, which is < halvingInterval, so full reward
        XCTAssertEqual(chainSpec.rewardAtBlock(0), initialReward)
        
        // Blocks 0-99: Public mining blocks, all get full reward due to large halvingInterval
        for blockIndex in 0..<100 {
            let expectedReward = chainSpec.rewardAtBlock(UInt64(blockIndex))
            // offsetBlockIndex = blockIndex + 100, still < halvingInterval (2^54)
            XCTAssertEqual(expectedReward, initialReward, "Public block \(blockIndex) should have full reward")
        }
        
        // Premine amount should equal rewards for 100 premine blocks
        XCTAssertEqual(chainSpec.premineAmount(), initialReward * 100)
        
        // Halving occurs when offsetBlockIndex reaches halvingInterval
        // offsetBlockIndex = blockIndex + premine = blockIndex + 100
        // So halving at blockIndex = halvingInterval - 100
        let firstHalvingBlock = halvingInterval - 100
        XCTAssertEqual(chainSpec.rewardAtBlock(firstHalvingBlock - 1), initialReward)
        XCTAssertEqual(chainSpec.rewardAtBlock(firstHalvingBlock), initialReward / 2)
        
        // Verify halving interval calculation
        XCTAssertEqual(halvingInterval, UInt64(1) << (64 - 10))  // 2^54
    }
    
    // MARK: - Batch Operations Tests
    
    func testRewardRange() {
        let chainSpec = ChainSpec(maxNumberOfTransactionsPerBlock: 1000, maxStateGrowth: 1000, premine: 0, targetBlockTime: 10_000, initialRewardExponent: 10)
        let initialReward = chainSpec.initialReward
        
        // Test range within single halving period
        let rewards = chainSpec.rewardRange(startBlock: 0, count: 10)
        XCTAssertEqual(rewards.count, 10)
        XCTAssertTrue(rewards.allSatisfy { $0 == initialReward })
        
        // Test empty range
        let emptyRewards = chainSpec.rewardRange(startBlock: 0, count: 0)
        XCTAssertEqual(emptyRewards.count, 0)
    }
    
    func testRewardRangeAcrossHalving() {
        let chainSpec = ChainSpec(maxNumberOfTransactionsPerBlock: 1000, maxStateGrowth: 1000, premine: 0, targetBlockTime: 10_000, initialRewardExponent: 4)  // Small exponent for testing
        let halvingInterval = chainSpec.halvingInterval
        let initialReward = chainSpec.initialReward
        
        // Get rewards spanning across halving boundary
        let rangeStart = halvingInterval - 2
        let rewards = chainSpec.rewardRange(startBlock: rangeStart, count: 4)
        
        XCTAssertEqual(rewards.count, 4)
        XCTAssertEqual(rewards[0], initialReward)      // Before halving
        XCTAssertEqual(rewards[1], initialReward)      // Before halving
        XCTAssertEqual(rewards[2], initialReward / 2)  // After halving
        XCTAssertEqual(rewards[3], initialReward / 2)  // After halving
    }
    
    // MARK: - Difficulty Adjustment Tests
    
    func testDifficultyCalculation() {
        let chainSpec = ChainSpec(maxNumberOfTransactionsPerBlock: 1000, maxStateGrowth: 1000, premine: 0, targetBlockTime: 60_000, initialRewardExponent: 10)  // 1 minute blocks
        
        let baseDifficulty = UInt256(1000)
        let currentTime: Int64 = 1000000  // Current time in milliseconds
        
        // Normal timing - should maintain similar difficulty
        let normalPreviousTime = currentTime - 60000  // Exactly target time (60 seconds = 60000 ms)
        let normalDifficulty = chainSpec.calculateMinimumDifficulty(
            previousDifficulty: baseDifficulty,
            blockTimestamp: currentTime,
            previousTimestamp: normalPreviousTime
        )
        XCTAssertEqual(normalDifficulty, baseDifficulty)
        
        // Fast blocks - difficulty should be harder (smaller number)
        let fastPreviousTime = currentTime - 30000  // Half target time (30 seconds = 30000 ms)
        let harderDifficulty = chainSpec.calculateMinimumDifficulty(
            previousDifficulty: baseDifficulty,
            blockTimestamp: currentTime,
            previousTimestamp: fastPreviousTime
        )
        XCTAssertTrue(harderDifficulty < baseDifficulty)
        
        // Slow blocks - difficulty should be easier (larger number)
        let slowPreviousTime = currentTime - 120000  // Double target time (120 seconds = 120000 ms)
        let easierDifficulty = chainSpec.calculateMinimumDifficulty(
            previousDifficulty: baseDifficulty,
            blockTimestamp: currentTime,
            previousTimestamp: slowPreviousTime
        )
        XCTAssertTrue(easierDifficulty > baseDifficulty)
    }
    
    // MARK: - Blockchain Convention Tests
    
    func testBitcoinLikeSpec() {
        let bitcoin = ChainSpec.bitcoin
        
        XCTAssertEqual(bitcoin.maxNumberOfTransactionsPerBlock, 3000)
        XCTAssertEqual(bitcoin.premine, 0)
        XCTAssertEqual(bitcoin.targetBlockTime, 600_000)  // 10 minutes
        XCTAssertEqual(bitcoin.initialRewardExponent, 26)
        XCTAssertTrue(bitcoin.isValid)
        
        // Test Bitcoin-like reward schedule
        XCTAssertGreaterThan(bitcoin.initialReward, 50_000_000)  // Greater than 50 * 10^6
    }
    
    func testEthereumLikeSpec() {
        let ethereum = ChainSpec.ethereum
        
        XCTAssertEqual(ethereum.maxNumberOfTransactionsPerBlock, 1000)
        XCTAssertEqual(ethereum.premine, 72_000_000)
        XCTAssertEqual(ethereum.targetBlockTime, 12_000)  // 12 seconds
        XCTAssertTrue(ethereum.isValid)
    }
    
    func testDevelopmentSpec() {
        let dev = ChainSpec.development
        
        XCTAssertEqual(dev.targetBlockTime, 1_000)  // 1 second blocks for fast testing
        XCTAssertGreaterThan(dev.premine, 0)
        XCTAssertTrue(dev.isValid)
    }
    
    // MARK: - Edge Cases and Performance Tests
    
    func testLargeBlockNumbers() {
        let chainSpec = ChainSpec(maxNumberOfTransactionsPerBlock: 1000, maxStateGrowth: 1000, premine: 0, targetBlockTime: 10_000, initialRewardExponent: 10)
        
        // Test with large block numbers
        let largeBlockReward = chainSpec.rewardAtBlock(UInt64.max / 2)
        XCTAssertGreaterThanOrEqual(largeBlockReward, 0)  // Should not crash or overflow
    }
    
    func testMaxSupplyCalculation() {
        let chainSpec = ChainSpec(maxNumberOfTransactionsPerBlock: 1000, maxStateGrowth: 1000, premine: 0, targetBlockTime: 10_000, initialRewardExponent: 10)
        let maxSupply = chainSpec.maxSupply
        
        // Max supply is now always UInt64.max for all chains
        XCTAssertEqual(maxSupply, UInt64.max)
        XCTAssertGreaterThan(maxSupply, chainSpec.initialReward)
    }
    
    func testTotalHalvings() {
        let chainSpec = ChainSpec(maxNumberOfTransactionsPerBlock: 1000, maxStateGrowth: 1000, premine: 0, targetBlockTime: 10_000, initialRewardExponent: 10)
        
        XCTAssertEqual(chainSpec.totalHalvings, 10)  // Same as initial reward exponent
        XCTAssertGreaterThan(chainSpec.totalHalvings, 0)
    }
    
    // MARK: - Performance Tests
    
    func testRewardCalculationPerformance() {
        let chainSpec = ChainSpec(maxNumberOfTransactionsPerBlock: 1000, maxStateGrowth: 1000, premine: 0, targetBlockTime: 10_000, initialRewardExponent: 20)
        
        measure {
            // Should be very fast due to bit operations
            for i in 0..<10000 {
                _ = chainSpec.rewardAtBlock(UInt64(i))
            }
        }
    }
    
    func testTotalRewardsPerformance() {
        let chainSpec = ChainSpec(maxNumberOfTransactionsPerBlock: 1000, maxStateGrowth: 1000, premine: 0, targetBlockTime: 10_000, initialRewardExponent: 20)
        
        measure {
            // Should be fast due to optimized algorithm
            _ = chainSpec.totalRewards(upToBlock: 1_000_000)
        }
    }
    
    func testBatchRewardPerformance() {
        let chainSpec = ChainSpec(maxNumberOfTransactionsPerBlock: 1000, maxStateGrowth: 1000, premine: 0, targetBlockTime: 10_000, initialRewardExponent: 20)
        
        measure {
            // Batch calculation should be efficient
            _ = chainSpec.rewardRange(startBlock: 0, count: 10000)
        }
    }
    
    // MARK: - Mathematical Correctness Tests
    
    func testGeometricSeriesCorrectness() {
        let chainSpec = ChainSpec(maxNumberOfTransactionsPerBlock: 1000, maxStateGrowth: 1000, premine: 0, targetBlockTime: 10_000, initialRewardExponent: 4)  // Small for easy calculation
        let initialReward = chainSpec.initialReward  // 16
        let halvingInterval = chainSpec.halvingInterval
        
        // Manual calculation for first two periods
        let firstPeriodRewards = initialReward * halvingInterval
        let secondPeriodRewards = (initialReward / 2) * halvingInterval
        let expectedTotal = firstPeriodRewards + secondPeriodRewards
        
        let calculatedTotal = chainSpec.totalRewards(upToBlock: halvingInterval * 2)
        XCTAssertEqual(calculatedTotal, expectedTotal)
    }
    
    func testRewardConsistency() {
        let chainSpec = ChainSpec(maxNumberOfTransactionsPerBlock: 1000, maxStateGrowth: 1000, premine: 0, targetBlockTime: 10_000, initialRewardExponent: 10)
        
        // Sum of individual rewards should equal total rewards
        let individualSum = (0..<100).reduce(0) { sum, blockIndex in
            sum + chainSpec.rewardAtBlock(UInt64(blockIndex))
        }
        
        let totalCalculated = chainSpec.totalRewards(upToBlock: 100)
        XCTAssertEqual(individualSum, totalCalculated)
    }
    
    // MARK: - New Functionality Tests
    
    func testTransactionCountValidation() {
        let chainSpec = ChainSpec(maxNumberOfTransactionsPerBlock: 1000, maxStateGrowth: 500, premine: 0, targetBlockTime: 10_000, initialRewardExponent: 10)
        
        XCTAssertTrue(chainSpec.validateTransactionCount(500))
        XCTAssertTrue(chainSpec.validateTransactionCount(1000))
        XCTAssertFalse(chainSpec.validateTransactionCount(1001))
    }
    
    func testStateGrowthValidation() {
        let chainSpec = ChainSpec(maxNumberOfTransactionsPerBlock: 1000, maxStateGrowth: 500, premine: 0, targetBlockTime: 10_000, initialRewardExponent: 10)
        
        XCTAssertTrue(chainSpec.validateStateGrowth(250))
        XCTAssertTrue(chainSpec.validateStateGrowth(500))
        XCTAssertFalse(chainSpec.validateStateGrowth(501))
    }
    
    func testUInt256Operations() {
        // Test UInt256 basic operations
        let small = UInt256(100)
        let large = UInt256(1000)
        
        XCTAssertTrue(small < large)
        XCTAssertTrue(small <= large)
        XCTAssertFalse(small == large)
        
        // Test hex string parsing
        let hexValue = UInt256("00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF", radix: 16)
        XCTAssertNotNil(hexValue)
        
        // Test invalid hex
        let invalidHex = UInt256("invalid", radix: 16)
        XCTAssertNil(invalidHex)
    }
    
    func testChainSpecDifferences() {
        let bitcoin = ChainSpec.bitcoin
        let development = ChainSpec.development
        
        XCTAssertNotEqual(bitcoin.targetBlockTime, development.targetBlockTime)
        XCTAssertNotEqual(bitcoin.maxNumberOfTransactionsPerBlock, development.maxNumberOfTransactionsPerBlock)
        XCTAssertNotEqual(bitcoin.premine, development.premine)
    }
    
    
    func testBlockchainConventionCompliance() {
        // All chains now use maxDifficultyChange = 2
        XCTAssertEqual(ChainSpec.maxDifficultyChange, 2)
        
        // Bitcoin conventions
        let bitcoin = ChainSpec.bitcoin
        XCTAssertEqual(bitcoin.maxNumberOfTransactionsPerBlock, 3000)
        XCTAssertEqual(bitcoin.premine, 0)
        XCTAssertEqual(bitcoin.targetBlockTime, 600_000)
        
        // Ethereum conventions  
        let ethereum = ChainSpec.ethereum
        XCTAssertLessThan(ethereum.maxNumberOfTransactionsPerBlock, bitcoin.maxNumberOfTransactionsPerBlock)
        XCTAssertGreaterThan(ethereum.premine, 0)
        XCTAssertEqual(ethereum.targetBlockTime, 12_000)
        
        // Development chain
        let dev = ChainSpec.development
        XCTAssertEqual(dev.targetBlockTime, 1_000)
    }
    
    func testDifficultyValidation() {
        let chainSpec = ChainSpec.development
        
        // Test difficulty validation
        let minimumDifficulty = UInt256(1000)
        let validDifficulty = UInt256(500)      // Smaller = harder, should be valid
        let invalidDifficulty = UInt256(2000)   // Larger = easier, should be invalid
        
        XCTAssertTrue(chainSpec.validateDifficulty(validDifficulty, minimumDifficulty: minimumDifficulty))
        XCTAssertFalse(chainSpec.validateDifficulty(invalidDifficulty, minimumDifficulty: minimumDifficulty))
        
        // Test block hash validation
        // Use a higher difficulty target (larger number = easier to mine)
        let difficulty = UInt256("1000000000000000000000000000000000000000000000000000000000000000", radix: 16)!
        let validHash = "0000123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF"    // This should be < difficulty (small hash value)
        let invalidHash = "FFFF123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF"   // This should be > difficulty (large hash value)
        
        XCTAssertTrue(chainSpec.validateBlockHash(validHash, difficulty: difficulty))
        XCTAssertFalse(chainSpec.validateBlockHash(invalidHash, difficulty: difficulty))
    }
    
    // MARK: - Comprehensive Premine Offset System Tests
    
    func testPremineOffsetBasicScenarios() {
        // Test with various premine sizes to ensure offset calculation is correct
        
        // Scenario 1: Zero premine (no offset)
        let noPremineChain = ChainSpec(
            maxNumberOfTransactionsPerBlock: 1000,
            maxStateGrowth: 1000,
            premine: 0,
            targetBlockTime: 60_000,
            initialRewardExponent: 10
        )
        
        XCTAssertEqual(noPremineChain.rewardAtBlock(0), noPremineChain.initialReward)
        XCTAssertEqual(noPremineChain.premineAmount(), 0)
        
        // Scenario 2: Small premine
        let smallPremineChain = ChainSpec(
            maxNumberOfTransactionsPerBlock: 1000,
            maxStateGrowth: 1000,
            premine: 10,
            targetBlockTime: 60_000,
            initialRewardExponent: 10
        )
        
        // Block 0 is first public block, offset = 0 + 10 = 10
        XCTAssertEqual(smallPremineChain.rewardAtBlock(0), smallPremineChain.initialReward)
        XCTAssertEqual(smallPremineChain.premineAmount(), smallPremineChain.initialReward * 10)
        
        // Scenario 3: Large premine (but still valid)
        let largePremineChain = ChainSpec(
            maxNumberOfTransactionsPerBlock: 1000,
            maxStateGrowth: 1000,
            premine: 1000000,
            targetBlockTime: 60_000,
            initialRewardExponent: 15  // Smaller exponent = larger halving interval
        )
        
        XCTAssertTrue(largePremineChain.isValid)
        XCTAssertEqual(largePremineChain.rewardAtBlock(0), largePremineChain.initialReward)
        XCTAssertEqual(largePremineChain.premineAmount(), largePremineChain.initialReward * 1000000)
    }
    
    func testPremineOffsetHalvingBoundaries() {
        // Test halving boundaries with different premine offsets
        let chainSpec = ChainSpec(
            maxNumberOfTransactionsPerBlock: 1000,
            maxStateGrowth: 1000,
            premine: 50,
            targetBlockTime: 60_000,
            initialRewardExponent: 8  // Smaller for easier testing
        )
        
        let halvingInterval = chainSpec.halvingInterval  // 2^(64-8) = 2^56
        let initialReward = chainSpec.initialReward       // 2^8 = 256
        
        // First halving occurs when offsetBlockIndex = blockIndex + 50 reaches halvingInterval
        // So blockIndex = halvingInterval - 50
        let firstHalvingPublicBlock = halvingInterval - 50
        
        // Blocks just before first halving should have full reward
        XCTAssertEqual(chainSpec.rewardAtBlock(firstHalvingPublicBlock - 5), initialReward)
        XCTAssertEqual(chainSpec.rewardAtBlock(firstHalvingPublicBlock - 1), initialReward)
        
        // Block at first halving should have half reward
        XCTAssertEqual(chainSpec.rewardAtBlock(firstHalvingPublicBlock), initialReward / 2)
        
        // Blocks after first halving should have half reward
        XCTAssertEqual(chainSpec.rewardAtBlock(firstHalvingPublicBlock + 1), initialReward / 2)
        XCTAssertEqual(chainSpec.rewardAtBlock(firstHalvingPublicBlock + 100), initialReward / 2)
        
        // Second halving occurs at firstHalvingPublicBlock + halvingInterval
        let secondHalvingPublicBlock = firstHalvingPublicBlock + halvingInterval
        
        // Blocks just before second halving should have half reward
        XCTAssertEqual(chainSpec.rewardAtBlock(secondHalvingPublicBlock - 1), initialReward / 2)
        
        // Block at second halving should have quarter reward
        XCTAssertEqual(chainSpec.rewardAtBlock(secondHalvingPublicBlock), initialReward / 4)
        
        // Blocks after second halving should have quarter reward
        XCTAssertEqual(chainSpec.rewardAtBlock(secondHalvingPublicBlock + 1), initialReward / 4)
    }
    
    func testPremineOffsetEdgeCases() {
        // Test edge cases around premine limits
        
        // Case 1: Maximum valid premine (just under halving interval)
        let testChain = ChainSpec(
            maxNumberOfTransactionsPerBlock: 1000,
            maxStateGrowth: 1000,
            premine: 100,
            targetBlockTime: 60_000,
            initialRewardExponent: 10
        )
        
        let maxValidPremine = testChain.halvingInterval - 1
        let maxPremineChain = ChainSpec(
            maxNumberOfTransactionsPerBlock: 1000,
            maxStateGrowth: 1000,
            premine: maxValidPremine,
            targetBlockTime: 60_000,
            initialRewardExponent: 10
        )
        
        XCTAssertTrue(maxPremineChain.isValid)
        
        // Block 0 should be on the verge of halving
        // offsetBlockIndex = 0 + maxValidPremine = halvingInterval - 1 (still full reward)
        XCTAssertEqual(maxPremineChain.rewardAtBlock(0), maxPremineChain.initialReward)
        
        // Block 1 should trigger halving
        // offsetBlockIndex = 1 + maxValidPremine = halvingInterval (half reward)
        XCTAssertEqual(maxPremineChain.rewardAtBlock(1), maxPremineChain.initialReward / 2)
        
        // Case 2: Invalid premine (equals halving interval)
        let invalidPremineChain = ChainSpec(
            maxNumberOfTransactionsPerBlock: 1000,
            maxStateGrowth: 1000,
            premine: testChain.halvingInterval,  // Invalid: equals halving interval
            targetBlockTime: 60_000,
            initialRewardExponent: 10
        )
        
        XCTAssertFalse(invalidPremineChain.isValid)
    }
    
    func testPremineOffsetConsistencyWithTotalRewards() {
        // Test that premine amount is consistent with total rewards calculation
        let chainSpec = ChainSpec(
            maxNumberOfTransactionsPerBlock: 1000,
            maxStateGrowth: 1000,
            premine: 1000,
            targetBlockTime: 60_000,
            initialRewardExponent: 10
        )
        
        let premineAmount = chainSpec.premineAmount()
        let expectedPremine = chainSpec.initialReward * 1000
        
        XCTAssertEqual(premineAmount, expectedPremine)
        
        // Verify this matches what totalRewards would calculate for the same number of blocks
        // Since premine blocks have the initial reward, this should be consistent
        let manualCalculation = chainSpec.totalRewards(upToBlock: 1000)
        XCTAssertEqual(premineAmount, manualCalculation)
    }
    
    func testPremineOffsetMultipleHalvings() {
        // Test premine offset behavior across multiple halving periods
        let chainSpec = ChainSpec(
            maxNumberOfTransactionsPerBlock: 1000,
            maxStateGrowth: 1000,
            premine: 25,
            targetBlockTime: 60_000,
            initialRewardExponent: 6  // Small for testing multiple halvings
        )
        
        let halvingInterval = chainSpec.halvingInterval  // 2^(64-6) = 2^58
        let initialReward = chainSpec.initialReward       // 2^6 = 64
        
        // Calculate halving boundaries for public blocks
        let firstHalvingBlock = halvingInterval - 25   // Account for premine offset
        let secondHalvingBlock = firstHalvingBlock + halvingInterval
        let thirdHalvingBlock = secondHalvingBlock + halvingInterval
        
        // Test rewards at each halving boundary
        XCTAssertEqual(chainSpec.rewardAtBlock(firstHalvingBlock - 1), initialReward)
        XCTAssertEqual(chainSpec.rewardAtBlock(firstHalvingBlock), initialReward / 2)
        
        XCTAssertEqual(chainSpec.rewardAtBlock(secondHalvingBlock - 1), initialReward / 2)
        XCTAssertEqual(chainSpec.rewardAtBlock(secondHalvingBlock), initialReward / 4)
        
        XCTAssertEqual(chainSpec.rewardAtBlock(thirdHalvingBlock - 1), initialReward / 4)
        XCTAssertEqual(chainSpec.rewardAtBlock(thirdHalvingBlock), initialReward / 8)
        
        // Verify premine amount
        XCTAssertEqual(chainSpec.premineAmount(), initialReward * 25)
    }
    
    func testPremineOffsetRewardRangeBehavior() {
        // Test that rewardRange works correctly with premine offset
        let chainSpec = ChainSpec(
            maxNumberOfTransactionsPerBlock: 1000,
            maxStateGrowth: 1000,
            premine: 100,
            targetBlockTime: 60_000,
            initialRewardExponent: 8  // Smaller for testing
        )
        
        let halvingInterval = chainSpec.halvingInterval
        let initialReward = chainSpec.initialReward
        let firstHalvingBlock = halvingInterval - 100  // Account for premine offset
        
        // Test range that spans the first halving
        let spanStart = firstHalvingBlock - 2
        let spanCount: UInt64 = 4
        let rewards = chainSpec.rewardRange(startBlock: spanStart, count: spanCount)
        
        XCTAssertEqual(rewards.count, 4)
        XCTAssertEqual(rewards[0], initialReward)      // Before halving
        XCTAssertEqual(rewards[1], initialReward)      // Before halving
        XCTAssertEqual(rewards[2], initialReward / 2)  // After halving
        XCTAssertEqual(rewards[3], initialReward / 2)  // After halving
        
        // Test range entirely in first period (all public blocks before halving)
        let earlyRewards = chainSpec.rewardRange(startBlock: 0, count: 10)
        XCTAssertEqual(earlyRewards.count, 10)
        XCTAssertTrue(earlyRewards.allSatisfy { $0 == initialReward })
    }
    
    func testPremineOffsetWithDifferentExponents() {
        // Test premine offset with various initial reward exponents
        let testCases: [(exponent: UInt8, premine: UInt64)] = [
            (5, 10),      // Small exponent, small premine
            (10, 100),    // Medium exponent, medium premine
            (15, 1000),   // Large exponent, large premine
            (20, 10000),  // Very large exponent, very large premine
        ]
        
        for (exponent, premine) in testCases {
            let chainSpec = ChainSpec(
                maxNumberOfTransactionsPerBlock: 1000,
                maxStateGrowth: 1000,
                premine: premine,
                targetBlockTime: 60_000,
                initialRewardExponent: exponent
            )
            
            XCTAssertTrue(chainSpec.isValid, "Chain with exponent \(exponent) and premine \(premine) should be valid")
            
            let initialReward = chainSpec.initialReward
            let halvingInterval = chainSpec.halvingInterval
            
            // Block 0 should always have initial reward (first public block)
            XCTAssertEqual(chainSpec.rewardAtBlock(0), initialReward, "Block 0 should have initial reward for exponent \(exponent)")
            
            // Premine amount should be consistent
            XCTAssertEqual(chainSpec.premineAmount(), initialReward * premine, "Premine amount should be correct for exponent \(exponent)")
            
            // First halving should occur at the right public block
            let firstHalvingBlock = halvingInterval - premine
            XCTAssertEqual(chainSpec.rewardAtBlock(firstHalvingBlock), initialReward / 2, "First halving should occur correctly for exponent \(exponent)")
        }
    }
    
    func testPremineOffsetTotalSupplyCalculations() {
        // Test that total supply calculations work correctly with premine offset
        let chainSpec = ChainSpec(
            maxNumberOfTransactionsPerBlock: 1000,
            maxStateGrowth: 1000,
            premine: 500,
            targetBlockTime: 60_000,
            initialRewardExponent: 10
        )
        
        let halvingInterval = chainSpec.halvingInterval
        let initialReward = chainSpec.initialReward
        let premineAmount = chainSpec.premineAmount()
        
        // Total rewards for first halving period of public mining
        let firstHalvingBlock = halvingInterval - 500
        let publicRewardsFirstPeriod = chainSpec.totalRewards(upToBlock: firstHalvingBlock)
        
        // This should equal initial reward * number of blocks in first period
        XCTAssertEqual(publicRewardsFirstPeriod, initialReward * firstHalvingBlock)
        
        // Total supply including premine for first period
        let totalSupplyFirstPeriod = premineAmount + publicRewardsFirstPeriod
        
        // Verify this is consistent
        XCTAssertEqual(totalSupplyFirstPeriod, initialReward * halvingInterval,
                      "Total supply (premine + public rewards) should equal full first period")
    }
    
    func testPremineOffsetRealWorldScenarios() {
        // Test with configurations similar to real blockchain networks
        
        // Bitcoin-like with small premine
        let bitcoinLikeWithPremine = ChainSpec(
            maxNumberOfTransactionsPerBlock: 3000,
            maxStateGrowth: 1_000_000,
            premine: 210_000,  // Equivalent to ~4 years of mining at 10min blocks
            targetBlockTime: 600_000,  // 10 minutes
            initialRewardExponent: 26
        )
        
        XCTAssertTrue(bitcoinLikeWithPremine.isValid)
        XCTAssertEqual(bitcoinLikeWithPremine.rewardAtBlock(0), bitcoinLikeWithPremine.initialReward)
        
        let bitcoinHalvingInterval = bitcoinLikeWithPremine.halvingInterval
        let bitcoinFirstHalvingBlock = bitcoinHalvingInterval - 210_000
        
        // Verify halving occurs at expected block
        XCTAssertEqual(bitcoinLikeWithPremine.rewardAtBlock(bitcoinFirstHalvingBlock - 1), bitcoinLikeWithPremine.initialReward)
        XCTAssertEqual(bitcoinLikeWithPremine.rewardAtBlock(bitcoinFirstHalvingBlock), bitcoinLikeWithPremine.initialReward / 2)
        
        // Ethereum-like with large premine (similar to existing ethereum spec)
        let ethereumLikeCustom = ChainSpec(
            maxNumberOfTransactionsPerBlock: 1000,
            maxStateGrowth: 24_000_000,
            premine: 72_000_000,  // Large premine like Ethereum
            targetBlockTime: 12_000,  // 12 seconds
            initialRewardExponent: 24
        )
        
        XCTAssertTrue(ethereumLikeCustom.isValid)
        XCTAssertEqual(ethereumLikeCustom.rewardAtBlock(0), ethereumLikeCustom.initialReward)
        XCTAssertEqual(ethereumLikeCustom.premineAmount(), ethereumLikeCustom.initialReward * 72_000_000)
        
        let ethHalvingInterval = ethereumLikeCustom.halvingInterval
        let ethFirstHalvingBlock = ethHalvingInterval - 72_000_000
        
        // Verify halving timing with large premine
        XCTAssertEqual(ethereumLikeCustom.rewardAtBlock(ethFirstHalvingBlock), ethereumLikeCustom.initialReward / 2)
    }
    
    func testPremineOffsetPerformanceWithLargeValues() {
        // Test performance and correctness with large premine values
        let largeChainSpec = ChainSpec(
            maxNumberOfTransactionsPerBlock: 10000,
            maxStateGrowth: 10_000_000,
            premine: 1_000_000_000,  // 1 billion premine blocks
            targetBlockTime: 30_000,  // 30 seconds
            initialRewardExponent: 30  // Large exponent to accommodate large premine
        )
        
        XCTAssertTrue(largeChainSpec.isValid)
        
        // Test that calculations don't overflow or cause performance issues
        measure {
            // These should all complete quickly due to bit operations
            _ = largeChainSpec.rewardAtBlock(0)
            _ = largeChainSpec.rewardAtBlock(1_000_000)
            _ = largeChainSpec.rewardAtBlock(100_000_000)
            _ = largeChainSpec.premineAmount()
        }
        
        // Verify correctness with large values
        XCTAssertEqual(largeChainSpec.rewardAtBlock(0), largeChainSpec.initialReward)
        XCTAssertEqual(largeChainSpec.premineAmount(), largeChainSpec.initialReward * 1_000_000_000)
        
        let largeHalvingInterval = largeChainSpec.halvingInterval
        let largeFirstHalvingBlock = largeHalvingInterval - 1_000_000_000
        
        // Verify halving still works correctly with large values
        XCTAssertEqual(largeChainSpec.rewardAtBlock(largeFirstHalvingBlock), largeChainSpec.initialReward / 2)
    }
}