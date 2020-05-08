const fs = require('fs');
const contract = JSON.parse(fs.readFileSync('eth-contracts/build/contracts/SolnSquareVerifier.json', 'utf8'));
console.log(JSON.stringify(contract.abi));