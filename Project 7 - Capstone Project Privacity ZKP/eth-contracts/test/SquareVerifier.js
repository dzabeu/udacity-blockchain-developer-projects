var SquareVerifier = artifacts.require('Verifier')

contract('SquareVerifier', accounts => {
    
    let proofFromZokrats = require("../../zokrates/code/square/proof.json");
    const owner = accounts[0]


    beforeEach(async function (){
        this.contract = await SquareVerifier.new({from: owner})
    })

     
    it('check incorrect proof', async function() {

        let  {
            proof : {a,b,c},
            inputs : inputs
        } = proofFromZokrats

        inputs = ["0x1000000000000000000000000000000000000000000000000000000000000009", "0x1000000000000000000000000000000000000000000000000000000000000001"]

        let result = await this.contract.verifyTx.call(a, b, c, inputs, {from: owner})

        assert.equal(false, result, "Invalid proof result");

    })
    it('check correct proof', async function() {
        const  {
            proof : {a,b,c},
            inputs : inputs
        } = proofFromZokrats

        let result = await this.contract.verifyTx.call(a, b, c, inputs, {from: owner});

        assert.equal(true, result, "Invalid proof result");

    })
   


})


