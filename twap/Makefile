# MemeTWAP Makefile

# Load environment variables
include .env
export

# Default target
.DEFAULT_GOAL := help

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

## Help
help: ## Show this help message
	@echo "$(GREEN)MemeTWAP Project Commands$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make $(YELLOW)<target>$(NC)\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

## Installation
install: ## Install dependencies
	@echo "$(GREEN)Installing Foundry dependencies...$(NC)"
	forge install foundry-rs/forge-std
	forge install OpenZeppelin/openzeppelin-contracts
	@echo "$(GREEN)Dependencies installed successfully!$(NC)"

## Building
build: ## Build the project
	@echo "$(GREEN)Building contracts...$(NC)"
	forge build

clean: ## Clean build artifacts
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	forge clean

## Testing
test: ## Run all tests
	@echo "$(GREEN)Running tests...$(NC)"
	forge test

test-verbose: ## Run tests with verbose output
	@echo "$(GREEN)Running tests with verbose output...$(NC)"
	forge test -vvv

test-gas: ## Run tests with gas reporting
	@echo "$(GREEN)Running tests with gas reporting...$(NC)"
	forge test --gas-report

test-coverage: ## Run tests with coverage
	@echo "$(GREEN)Running tests with coverage...$(NC)"
	forge coverage

test-specific: ## Run specific test (usage: make test-specific TEST=testUpdatePrice)
	@echo "$(GREEN)Running specific test: $(TEST)$(NC)"
	forge test --match-test $(TEST) -vvv

## Deployment
deploy-local: ## Deploy to local network
	@echo "$(GREEN)Deploying to local network...$(NC)"
	forge script script/DeployTWAP.s.sol --rpc-url http://localhost:8545 --broadcast

deploy-testnet: ## Deploy to testnet
	@echo "$(GREEN)Deploying to testnet...$(NC)"
	forge script script/DeployTWAP.s.sol --rpc-url $(RPC_URL) --broadcast --verify

deploy-mainnet: ## Deploy to mainnet (requires confirmation)
	@echo "$(RED)WARNING: Deploying to mainnet!$(NC)"
	@read -p "Are you sure? (y/N): " confirm && [ "$$confirm" = "y" ]
	forge script script/DeployTWAP.s.sol --rpc-url $(RPC_URL) --broadcast --verify

## Verification
verify: ## Verify contract on Etherscan
	@echo "$(GREEN)Verifying contract...$(NC)"
	forge verify-contract $(CONTRACT_ADDRESS) src/MemeTWAP.sol:MemeTWAP --etherscan-api-key $(ETHERSCAN_API_KEY)

## Formatting
format: ## Format code
	@echo "$(GREEN)Formatting code...$(NC)"
	forge fmt

format-check: ## Check code formatting
	@echo "$(GREEN)Checking code formatting...$(NC)"
	forge fmt --check

## Analysis
analyze: ## Run static analysis
	@echo "$(GREEN)Running static analysis...$(NC)"
	slither src/

gas-snapshot: ## Create gas snapshot
	@echo "$(GREEN)Creating gas snapshot...$(NC)"
	forge snapshot

## Documentation
docs: ## Generate documentation
	@echo "$(GREEN)Generating documentation...$(NC)"
	forge doc

docs-serve: ## Serve documentation locally
	@echo "$(GREEN)Serving documentation at http://localhost:3000$(NC)"
	forge doc --serve --port 3000

## Utilities
flatten: ## Flatten contracts
	@echo "$(GREEN)Flattening contracts...$(NC)"
	forge flatten src/MemeTWAP.sol > flattened/MemeTWAP.sol

setup-env: ## Setup environment file
	@if [ ! -f .env ]; then \
		echo "$(YELLOW)Creating .env file from .env.example...$(NC)"; \
		cp .env.example .env; \
		echo "$(GREEN).env file created! Please update it with your values.$(NC)"; \
	else \
		echo "$(YELLOW).env file already exists.$(NC)"; \
	fi

check-env: ## Check environment variables
	@echo "$(GREEN)Checking environment variables...$(NC)"
	@echo "PRIVATE_KEY: $(if $(PRIVATE_KEY),✓ Set,✗ Not set)"
	@echo "RPC_URL: $(if $(RPC_URL),✓ Set,✗ Not set)"
	@echo "MEME_FACTORY_ADDRESS: $(if $(MEME_FACTORY_ADDRESS),✓ Set,✗ Not set)"
	@echo "ETHERSCAN_API_KEY: $(if $(ETHERSCAN_API_KEY),✓ Set,✗ Not set)"

## All-in-one commands
setup: install setup-env ## Setup the project
	@echo "$(GREEN)Project setup complete!$(NC)"

ci: format-check build test ## Run CI pipeline
	@echo "$(GREEN)CI pipeline completed successfully!$(NC)"

.PHONY: help install build clean test test-verbose test-gas test-coverage test-specific deploy-local deploy-testnet deploy-mainnet verify format format-check analyze gas-snapshot docs docs-serve flatten setup-env check-env setup ci