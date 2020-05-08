

// const HDWalletProvider = require('truffle-hdwallet-provider');
// const infuraKey = "infurakeyproject here";
// const mnemonic = "insert mneminic here";

const HDWalletProvider = require('truffle-hdwallet-provider');
const infuraKey = "<INFURAKEY>";
const mnemonic = "<MNEMONIC>";
//senha123 mnemonic

module.exports = {

  networks: {
    development: {
      host: "127.0.0.1",     // Localhost (default: none)
      port: 8545,            // Standard Ethereum port (default: none)
      network_id: "*",       // Any network (default: none)
     },
    rinkeby: {
      provider: () => new HDWalletProvider(mnemonic, `https://rinkeby.infura.io/v3/${infuraKey}`),
        network_id: 4,       // rinkeby's id
        gas: 4500000,        // rinkeby has a lower block limit than mainnet
        gasPrice: 10000000000
    },
  }
    
  }
