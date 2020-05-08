   
# Ethereum Dapp for Tracking Items through Supply Chain


Ethereum DApp that demonstrates a supply chain flow between a seller and a buyer.
The user story is similar to any common supply chain process.
The seller can add items to the inventory stored on the blockchain.
The buyer can purchase these items from the inventory system. The seller can mark an item as shipped, and in the same way, a buyer can mark an item that has been sold.


# Install dependencies

1. Install library : 
  npm install

2. Install and open ganache on 8545 port
   
3. Deploy contracts 
  npx truffle migrate --reset --network development

4. Test contracts:
  npx truffle test --network development

5. Run application 
   npm run start


# Examples

Contracts (Rinkeby):

FarmerRole
0x9D14D06e34102158b6Dc9651aCfCE2B97084b686

DistributorRole
0xaeE4d93B9c0b5d56B79B4656a19db405502FD78D

RetailerRole
0x2A1DEaBeB0b593Dfc75533f8715c780Aff214fb7

ConsumerRole
0xE25E2F25857Ec085E36819E21B0e4AC2B9EC8941

SupplyChain
0x0dE60b87f0C95399F9CFE6C9617BFfF2d7D4C88D


Transaction Examples:

  Harvest:
  https://rinkeby.etherscan.io/tx/0x6740758cdb315f9088876a8663cb693288bc03b81fe010dfbeb7d16df68fe9e9

  Process
  https://rinkeby.etherscan.io/tx/0xebce5b9f423432636069e67582df8d3958e19cfdbba86728e2230443992c933f

  Pack
  https://rinkeby.etherscan.io/tx/0xa7270c9e8ef97a5138df19f337503e287fea837d318541b85df72fe40df86b96

  ForSale
  https://rinkeby.etherscan.io/tx/0x2d129b153eb8c0d5e186013ef54d04e5945815fcf4f0bbe029b8b5f3afa2b355

  Buy
  https://rinkeby.etherscan.io/tx/0xeb572beb0f7d2b204414cf4448f8e011fbbb267fd0f5d9b1453f4e7f9bb8f735

  Ship
  https://rinkeby.etherscan.io/tx/0x302b1740c8e0290852fba6ef83e7d3930322fe4d92570a81896c84d0a6c23e32

  Receive
  https://rinkeby.etherscan.io/tx/0x81cca1ab747f4774290b8988e6471fe731a27008e8eb52179be977ec6d6303a2

  Purcharse
  https://rinkeby.etherscan.io/tx/0x32cd10306bc618a36983b8b8e1b12eef0bf7e375921df3dc8d26d162214be272

