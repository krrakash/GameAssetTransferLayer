# 🕹️ CrossChainTransfer Contract for Game Assets

> **Effortless Cross-Chain Transfers of In-Game Assets with LayerZero**  
> ⚔️ **Bridge game items, collectibles, and tokens across Ethereum, Polygon, and more!**

---

### Overview

The **CrossChainTransfer** contract is designed to seamlessly transfer in-game assets and collectibles across multiple blockchains. Leveraging LayerZero's ultra-light nodes, this contract supports **game-based assets** like **weapons, armor, skins, collectibles, tokens**, and **multi-tokens (ERC-1155)** across LayerZero-supported chains such as **Ethereum, Polygon**, and others.

### 🎮 Key Features

- **In-Game Asset Compatibility**: Supports **ERC-1155 multi-token assets** commonly used in games (e.g., items, power-ups, skins, and loot).
- **Cross-Chain Flexibility**: Configured for LayerZero-compatible chains, enabling you to bridge assets across major blockchains.
- **NFT and Token Support**: Also handles **ERC-721 NFTs** for unique items and **ERC-20** for game-specific or ecosystem tokens.
- **Non-Standard Token Handling**: Supports tokens like **USDT** and **USDC**, accommodating tokens with non-standard behaviors.
- **Security with LayerZero’s Trusted Remotes**: Ensures that only verified cross-chain messages are processed.

### ⚔️ Non-Standard Token Support

This contract is equipped to handle **non-standard tokens** (like **USDT** and **USDC**) which may deviate from the ERC-20 standard. It uses **low-level calls** to manage these tokens by:

- Calling `transfer` and `transferFrom` using low-level `call` to ensure compatibility.
- Verifying the call was successful and checking return data if present, to handle tokens that don’t return a value.

```solidity
function _safeERC20Transfer(
    address _token,
    address _to,
    uint256 _amount
) internal {
    (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(IERC20.transfer.selector, _to, _amount));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "ERC20 transfer failed");
}
```
### 🕹️ How It Works

**Initiate Transfer**: A player or game platform calls `sendCrossChain`, specifying:

- **Token Type** (ERC-1155 for game items, ERC-721 for unique collectibles, ERC-20 for currency)
- **Amount or Token ID** (e.g., weapon ID, quantity of resources)
- **Recipient Address** (player’s address on the destination chain)
- **Destination Chain ID**

**Message Verification**: LayerZero’s **oracles** and **relayers** verify and route the transaction securely to the destination chain.

**Asset Receipt**: The contract’s `_nonblockingLzReceive` function processes the message and delivers the item or asset to the player’s address on the destination chain.

### 🔧 Setup & Deployment

- **Deploy on Each Chain**: Deploy the contract on each network you wish to connect for asset bridging.
- **Set Trusted Remotes**: Configure each contract’s address as a trusted remote on the corresponding chain for secure authorization.

Example constructor usage:

```solidity
// Deploy with LayerZero endpoint for your chain and the contract owner address
CrossChainTransfer contract = new CrossChainTransfer(_lzEndpoint, initialOwner);
