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

# Build & Test
.PHONY: build test clean

build:
	forge build

test:
	forge test -vvv

clean:
	forge clean

# Deployment commands
.PHONY: deploy-polygon deploy-mumbai deploy-local

deploy-polygon:
	@echo "Deploying to Polygon Mainnet..."
	forge script script/deploy.s.sol:DeployScript \
		--rpc-url $(RPC_POLYGON) \
		--broadcast \
		--verify \
		--etherscan-api-key ${POLYGONSCAN_API_KEY} \
		--with-gas-price $$(cast gas-price) \
		-vvvv

deploy-mumbai:
	@echo "Deploying to Mumbai Testnet..."
	forge script script/deploy.s.sol:DeployScript \
		--rpc-url $(RPC_MUMBAI) \
		--broadcast \
		--verify \
		--etherscan-api-key ${POLYGONSCAN_API_KEY} \
		-vvvv

deploy-local:
	@echo "Deploying to local network..."
	forge script script/deploy.s.sol:DeployScript \
		--rpc-url $(RPC_LOCAL) \
		--broadcast \
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