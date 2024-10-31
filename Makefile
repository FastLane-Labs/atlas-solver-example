# Include .env file if it exists
-include .env

# Network configuration
NETWORK_POLYGON := polygon
NETWORK_MUMBAI := mumbai
NETWORK_LOCAL := local

# RPC URLs (override these in .env)
RPC_POLYGON ?= https://polygon-mainnet.g.alchemy.com/v2/your-api-key
RPC_MUMBAI ?= https://polygon-mumbai.g.alchemy.com/v2/your-api-key
RPC_LOCAL ?= http://localhost:8545

# Contract addresses per network
WMATIC_POLYGON := 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270
WMATIC_MUMBAI := 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889

ATLAS_POLYGON := 0x0
ATLAS_MUMBAI := 0x0

# Keystore configuration
KEYSTORE_PATH ?= ${HOME}/.foundry/keystores
KEYSTORE_NAME ?= deployer

# Build & Test
.PHONY: build test clean

build:
	forge build

test:
	forge test -vvv

clean:
	forge clean

# Keystore management
.PHONY: new-wallet import-wallet list-wallets

new-wallet:
	@echo "Generating new wallet..."
	@cast wallet new

import-wallet:
	@echo "Importing wallet to keystore..."
	@mkdir -p ${KEYSTORE_PATH}
	@cast wallet import ${KEYSTORE_NAME} --interactive

list-wallets:
	@echo "Available keystores:"
	@ls -la ${KEYSTORE_PATH}

# Deployment commands
.PHONY: deploy-polygon deploy-mumbai deploy-local

deploy-polygon:
	@if [ -z "${KEYSTORE_PASSWORD}" ]; then \
		echo "Error: KEYSTORE_PASSWORD is required"; \
		exit 1; \
	fi
	@echo "Deploying to Polygon Mainnet..."
	forge script script/deploy.s.sol:DeployScript \
		--rpc-url $(RPC_POLYGON) \
		--broadcast \
		--verify \
		--etherscan-api-key ${POLYGONSCAN_API_KEY} \
		--account ${KEYSTORE_NAME} \
		--password ${KEYSTORE_PASSWORD} \
		--with-gas-price $$(cast gas-price) \
		-vvvv

deploy-mumbai:
	@if [ -z "${KEYSTORE_PASSWORD}" ]; then \
		echo "Error: KEYSTORE_PASSWORD is required"; \
		exit 1; \
	fi
	@echo "Deploying to Mumbai Testnet..."
	forge script script/deploy.s.sol:DeployScript \
		--rpc-url $(RPC_MUMBAI) \
		--broadcast \
		--verify \
		--etherscan-api-key ${POLYGONSCAN_API_KEY} \
		--account ${KEYSTORE_NAME} \
		--password ${KEYSTORE_PASSWORD} \
		-vvvv

deploy-local: anvil
	@echo "Deploying to local network..."
	@echo "Using default anvil private key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
	forge script script/deploy.s.sol:DeployScript \
		--rpc-url $(RPC_LOCAL) \
		--broadcast \
		--private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
		-vvvv

# Helper commands
.PHONY: install-deps update-deps

install-deps:
	forge install OpenZeppelin/openzeppelin-contracts
	forge install vectorized/solady
	forge install foundry-rs/forge-std

update-deps:
	forge update

# Environment setup
.PHONY: setup

setup: install-deps build

# Local chain management
.PHONY: anvil stop-anvil

# Start local chain
anvil:
	@echo "Starting local chain..."
	@anvil --port 8545 > anvil.log 2>&1 & echo $$! > anvil.pid

# Stop local chain
stop-anvil:
	@if [ -f anvil.pid ]; then \
		echo "Stopping local chain..."; \
		kill -9 `cat anvil.pid`; \
		rm anvil.pid anvil.log; \
	fi