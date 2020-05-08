var OpenSea = artifacts.require('OpenSeaToken721')
const truffleAssert = require('truffle-assertions')

contract('ERC721Mintable', accounts => {

    const account_one = accounts[0]
    const account_two = accounts[1]
    const name = "OpenSeaToken721"
    const symbol = "OST"

    describe('match erc721 spec', function () {
        beforeEach(async function () { 
            this.contract = await OpenSea.new(name, symbol, {from: account_one})
            for(let i = 1; i < 11; i++){
                await this.contract.mint(account_one, i, {from: account_one})
            }

        })


        it('Transfer tken from  owner to a new wallet', async function () { 
            let tx = await this.contract.transferFrom(account_one, account_two, 6) 
            let tokenOwner = await this.contract.ownerOf.call(6)
            assert.equal(tokenOwner, account_two, 'Invalid new Owner')
            assert.equal(tx.logs[0].event, "Transfer", 'Invalid event emitted')
        })

        it('get token balance', async function () { 
            let tokenBalance = await this.contract.balanceOf.call(account_one)
            assert.equal(tokenBalance, 10, "Token balance is not valid")
        })

        it('return uri', async function () { 
            let tokenURI = await this.contract.tokenURI.call(5)
            assert.equal(tokenURI, "https://s3-us-west-2.amazonaws.com/udacity-blockchain/capstone/5", "Token URI is not valid")
            
        })

        it('return supply', async function () { 
            let totalSupply = await this.contract.totalSupply.call()
             assert.equal(totalSupply, 10, "Invalid total supply")
             
         })

    })

    describe('have properties', function () {
        beforeEach(async function () { 
            this.contract = await OpenSea.new(name, symbol, {from: account_one})
        })

        it('transfering contract owner only if the caller the owner', async function () { 
            let tx = await this.contract.transferOwnership(account_two, {from: account_one})
            let owner = await this.contract.owner.call()
            assert.equal(owner, account_two, 'Invalid contract owner')
            assert.equal(tx.logs[0].event, "OwnershipTransfered", 'Invalid event emitted')
        })

        it('return contract owner', async function () { 
            let owner = await this.contract.owner.call()
            assert.equal(owner, account_one, 'Invalid contract owner')
            
        })

        it('fail minting if address is not contract owner', async function () { 
            await truffleAssert.reverts(this.contract.mint(account_two, 11, {from: account_two}), "This wallet is not the owner")
        })

        

        it(' fail transfering if the caller is not the current owner', async function () { 
            await truffleAssert.reverts(this.contract.transferOwnership(account_two, {from: account_two}), "This wallet is not the owner")
        })

        

    })

    describe('have Pausable properties', function () {
        beforeEach(async function () { 
            this.contract = await OpenSea.new(name, symbol, {from: account_one})
        })


        it('not mint if contract paused', async function () { 
            await this.contract.pause({from:account_one})
            await truffleAssert.reverts(this.contract.mint(account_one, 20, {from: account_one}), "contract is paused")
        })


        it('not pause if already pause ', async function () { 
            await truffleAssert.reverts(this.contract.unpause({from: account_one}), "contract is not paused")
        })


        it('fail when trying to pause contract if the caller  is not contract owner', async function () { 
            await truffleAssert.reverts(this.contract.pause({from: account_two}), "This wallet is not the owner")
        })

        it('fail when trying to unpause contract if the caller  is not contract owner', async function () { 
            await this.contract.pause({from:account_one})
            await truffleAssert.reverts(this.contract.unpause({from: account_two}), "This wallet is not the owner")
        })

    
        it('allow contract owner to pause contract if the contract unpaused', async function () { 
            let tx = await this.contract.pause({from:account_one})
            assert.equal(tx.logs[0].event, "Paused", 'Invalid event emitted')
        })

        it('allow contract owner to unpause contract if the contract paused', async function () { 
            await this.contract.pause({from:account_one})
            let tx = await this.contract.unpause({from:account_one})
            assert.equal(tx.logs[0].event, "Unpaused", 'Invalid event emittDDed')
        })

        it('should not allow contract owner to pause contract if the contract paused', async function () { 
            await this.contract.pause({from:account_one})
            await truffleAssert.reverts(this.contract.pause({from: account_one}), "contract is paused")
        })

    })

})