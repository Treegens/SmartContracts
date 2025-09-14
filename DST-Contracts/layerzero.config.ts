import { defineConfig } from "@layerzerolabs/toolbox";

export default defineConfig({
  networks: {
    base: {
      eid: 30184,
      name: "base",
      rpc: "https://base-mainnet.g.alchemy.com/v2/${RPC_API_KEY}",
      contracts: {
        BaseMgroOapp: "0x735976BD7F55c3bB1ae101F7B4b6b7208504296E",
        TreegenNFT: "0xef8B62026895A09D6A631181008969677b7A5ABB"
      }
    },
    celo: {
      eid: 30125,
      name: "celo", 
      rpc: "https://celo-mainnet.g.alchemy.com/v2/${RPC_API_KEY}",
      contracts: {
        CeloMgroOapp: "0x43576228672F058dE4131A1C0996A920E3B68028"
      }
    },
    ethereum: {
      eid: 30101,
      name: "ethereum",
      rpc: "https://eth-mainnet.g.alchemy.com/v2/${RPC_API_KEY}",
      contracts: {
        TreegenNFT: "0xef8B62026895A09D6A631181008969677b7A5ABB"
      }
    }
  },
  contracts: {
    BaseMgroOapp: {
      address: {
        base: "0x735976BD7F55c3bB1ae101F7B4b6b7208504296E"
      },
      source: "BaseMgroOapp.sol"
    },
    CeloMgroOapp: {
      address: {
        celo: "0x43576228672F058dE4131A1C0996A920E3B68028"
      },
      source: "CeloMgroOapp.sol"
    },
    TreegenNFT: {
      address: {
        base: "0xef8B62026895A09D6A631181008969677b7A5ABB",
        ethereum: "0xef8B62026895A09D6A631181008969677b7A5ABB"
      },
      source: "TreegenNFT.sol"
    }
  }
});