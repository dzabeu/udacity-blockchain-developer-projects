### Prerequisites

Install the following itens to use this example
- POSTMAN
- Node JS

### Install dependencies 

open a terminal and run the command `npm install`

### To run locally, execute the following command on terminal 

open a terminal and run the command `node app.js`

### Create the calls using Postman

1. Allows user to request Ownership of a Wallet address 

http://localhost:8000/requestValidation

Body

```
{
	"address":"<Address>"
}
```

1. Allow Submit a Star, you need first to `requestValidation` to have the message

http://localhost:8000/submitStar

Body

```
{
	"address":"<Address>",
	"signature":"<Sign>",
	"message":"<Message to add>",
	"star": {
		"dec": "68 53 56.9",
		"ra": "16h 29m 1.0s",
		"story": "Magic"
	}
}
```

1. Allows to retrieve the block by Height ]

http://localhost:8000/block/<height>

2. Allows to retrieve the block by hash

http://localhost:8000/block/<hash>

3. Allows you to request the list of Stars registered by an owner

http://localhost:8000/blocks/<Address>


