# Blockchain Capstone: Final Project

Blockchain Capstone: Final project Udacity -  Real Estate Marketplace 
Final project of the Udacity course (Blockchain) where it is necessary to create own tokens to represent the title of the properties. Before entering the token, the owner needs to verify that he owns the property. Through A zk-SNARKs (zoKrates), a verification system is created that can prove ownership of the property title without revealing this specific information. If it is successfully verified, it will be placed on the blockchain market (OpenSea) for others to buy.


# Getting Started

1. Install Packages

```
npm install
npm install truffle-assertions
```
## Deploying in the Rinkeby test network

1. Deploy in the Rinkeby test network with truffle
```
truffle migrate --reset --compile-all --network rinkeby
```

## Example of Contracts on Rinkeby Network
  Replacing 'Verifier'
   --------------------
   > transaction hash:    0x09e3ad7ab4ef53a0885c8c1549415124121752a301a42a23786f9736b055f7ae
   > contract address:    0xEd2fb4B37Bc841022Afdf38D5a4bf403de310453
   > account:             0x3e31B2a2784FDf3b03b4401C53dE19063f4A512E


   Replacing 'OpenSeaToken721'
   -------------------------------
   > transaction hash:    0x24a17092796e59378f184a770ed00f58ae110454943bd474457b6264353a760f
   > contract address:    0x7b59F36FfAB7847329dc1B6EF93d968bea35a0EC
   > account:             0x3e31B2a2784FDf3b03b4401C53dE19063f4A512E


   Replacing 'SolnSquareVerifier'
   ------------------------------
   > transaction hash:    0x128ff8687e4606986195d50ee3529c4cc61158a40b3cbfe89690602a88c13b48
   > contract address:    0x52da3208E23EEf41De5fC545Cd05E140C7a1D6c7
   > account:             0x3e31B2a2784FDf3b03b4401C53dE19063f4A512E


## Contract ABI
 Contract ABI can be found on `eth-contracts/build/contracts` folder on github repository
 
## OpenSea MarketPlace Storefront link

- Token : https://rinkeby.opensea.io/assets/openseadzcaps
- Old Owner Token : https://rinkeby.opensea.io/accounts/0x3e31B2a2784FDf3b03b4401C53dE19063f4A512E?tab=activity
- Buyer  : https://rinkeby.opensea.io/accounts/0x1904644Ec4eF7e7FF0AF39938475F36c1771D022?tab=activity


# To exec test (on eth-contracts)

truffle test 

Result:

```
  Contract: TestERC721Mintable
    match erc721 spec
      ✓ Transfer tken from  owner to a new wallet (156ms)
      ✓ get token balance (51ms)
      ✓ return uri (57ms)
      ✓ return supply (52ms)
    have properties
      ✓ transfering contract owner only if the caller the owner (107ms)
      ✓ return contract owner
      ✓ fail minting if address is not contract owner (57ms)
      ✓  fail transfering if the caller is not the current owner (45ms)
    have Pausable properties
      ✓ not mint if contract paused (110ms)
      ✓ not pause if already pause  (48ms)
      ✓ fail when trying to pause contract if the caller  is not contract owner (49ms)
      ✓ fail when trying to unpause contract if the caller  is not contract owner (141ms)
      ✓ allow contract owner to pause contract if the contract unpaused
      ✓ allow contract owner to unpause contract if the contract paused (125ms)
      ✓ should not allow contract owner to pause contract if the contract paused (109ms)

  Contract: TestSolnSquareVerifier
    ✓ Add solution (95ms)
    ✓ Avoid add a solution already used (181ms)
    ✓ mint a new Opensea token (1786ms)
    ✓ avoit mint a new token Opensea with a wrong proof (3363ms)

  Contract: TestSquareVerifier
    ✓ check incorrect proof (1806ms)
    ✓ check correct proof (1509ms)


  21 passing (25s)
  ```


# TO create proof zk-SNARKs
  
docker run -v NOME_DA_PROVA:/home/zokrates/code -ti zokrates/zokrates /bin/bash
./zokrates compile -i square.code
./zokrates setup
./zokrates  export-verifier
./zokrates  compute-witness -a 2 4
./zokrates  generate-proof
docker cp CONTAINER_ID:<dir>/verifier.sol <project folder>
docker cp CONTAINER_ID:<dir>/proving.key  <project folder>
docker cp CONTAINER_ID:<dir>/out <project folder>
docker cp CONTAINER_ID:<dir>/proof.json <project folder>


