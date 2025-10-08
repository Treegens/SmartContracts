#!/bin/bash

# Enhanced Diamond Test Runner
# Runs comprehensive tests for all audit fixes

echo "🔍 Running Enhanced Diamond Security Tests..."
echo "=============================================="

# Test 1: Constructor Validation Tests
echo "📋 Testing Constructor Validation..."
forge test --match-contract DiamondEnhancedTest --match-test "testConstructorValidation" -vv

# Test 2: Timelock Ownership Tests
echo "⏰ Testing Timelock Ownership..."
forge test --match-contract DiamondEnhancedTest --match-test "testTimelockOwnership" -vv

# Test 3: Fund Management Tests
echo "💰 Testing Fund Management..."
forge test --match-contract DiamondEnhancedTest --match-test "testFundManagement" -vv

# Test 4: Diamond Integrity Tests
echo "🔧 Testing Diamond Integrity..."
forge test --match-contract DiamondEnhancedTest --match-test "testDiamondIntegrity" -vv

# Test 5: Fallback Validation Tests
echo "🔄 Testing Fallback Validation..."
forge test --match-contract DiamondEnhancedTest --match-test "testFallbackValidation" -vv

# Test 6: Integration Tests
echo "🔗 Testing Integration..."
forge test --match-contract DiamondEnhancedTest --match-test "testIntegration" -vv

# Test 7: Edge Cases
echo "⚠️  Testing Edge Cases..."
forge test --match-contract DiamondEnhancedTest --match-test "testEdgeCase" -vv

# Test 8: Gas Optimization
echo "⛽ Testing Gas Optimization..."
forge test --match-contract DiamondEnhancedTest --match-test "testGasOptimization" -vv

# Test 9: Event Tests
echo "📡 Testing Events..."
forge test --match-contract DiamondEnhancedTest --match-test "testEvent" -vv

# Test 10: Helper Functions
echo "🛠️  Testing Helper Functions..."
forge test --match-contract DiamondEnhancedTest --match-test "testHelper" -vv

# Run all enhanced tests
echo "🚀 Running All Enhanced Diamond Tests..."
forge test --match-contract DiamondEnhancedTest -vv

echo "✅ Enhanced Diamond Tests Complete!"
echo "=============================================="
