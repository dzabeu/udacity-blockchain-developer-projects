pragma solidity ^0.5.8;

import '../coffeeaccesscontrol/AccessControl.sol';
import '../coffeecore/Ownable.sol';

// Define a contract 'Supplychain'
contract SupplyChain is Ownable, AccessControl  {

  // Define 'owner'
  // address owner;

  // Define a variable called 'upc' for Universal Product Code (UPC)
  uint  upc;

  // Define a variable called 'sku' for Stock Keeping Unit (SKU)
  uint  sku;

  // Define a public mapping 'items' that maps the UPC to an Item.
  mapping (uint => Item) items;

  //public mapping 'itemsHistory' that maps the UPC to an array of TxHash
  mapping (uint => string[]) itemsHistory;
  
  // Define enum 'State' with the following values:
  enum State
  {
    New,        // 0
    Harvested,  // 1
    Processed,  // 2
    Packed,     // 3
    ForSale,    // 4
    Sold,       // 5
    Shipped,    // 6
    Received,   // 7
    Purchased   // 8
    }

  State constant defaultState = State.Harvested;

  // Define a struct 'Item' with the following fields:
  struct Item {
    uint    sku;  // Stock Keeping Unit (SKU)
    uint    upc; // Universal Product Code (UPC), generated by the Farmer, goes on the package, can be verified by the Consumer
    address ownerID;  // Metamask-Ethereum address of the current owner as the product moves through 8 stages
    address originFarmerID; // Metamask-Ethereum address of the Farmer
    string  originFarmName; // Farmer Name
    string  originFarmInformation;  // Farmer Information
    string  originFarmLatitude; // Farm Latitude
    string  originFarmLongitude;  // Farm Longitude
    uint    productID;  // Product ID potentially a combination of upc + sku
    string  productNotes; // Product Notes
    uint    productPrice; // Product Price
    State   itemState;  // Product State as represented in the enum above
    address distributorID;  // Metamask-Ethereum address of the Distributor
    address retailerID; // Metamask-Ethereum address of the Retailer
    address consumerID; // Metamask-Ethereum address of the Consumer
  }

  // Define 8 events with the same 8 state values and accept 'upc' as input argument
  event Harvested(uint indexed upc);
  event Processed(uint indexed upc);
  event Packed(uint indexed upc);
  event ForSale(uint indexed upc,uint price);
  event Sold(uint indexed upc,address distributorID);
  event Shipped(uint indexed upc);
  event Received(uint indexed upc,address retailerID);
  event Purchased(uint indexed upc, address purchaserID);

  // Define a modifer that checks to see if msg.sender == owner of the contract
  // modifier onlyOwner() {
  //   require(msg.sender == owner);
  //   _;
  // }

  // Define a modifer that verifies the Caller
  modifier verifyCaller (address _address) {
    require(msg.sender == _address); 
    _;
  }


  // Define a modifier that checks if the paid amount is sufficient to cover the price
  modifier paidEnough(uint _price) { 
    require(msg.value >= _price); 
    _;
  }
  
  // Define a modifier that checks the price and refunds the remaining balance
  modifier checkValue(uint _upc) {
    _;
    uint _price = items[_upc].productPrice;
    uint amountToReturn = msg.value - _price;
    msg.sender.transfer(amountToReturn);
  }


  modifier onlyItemOwnerOrOwner(uint _upc) {
    require(items[_upc].ownerID == msg.sender || isOwner(),"caller is not the owner of the item");
    _;
  }

  modifier newitem(uint _upc) {
    require(items[_upc].itemState == State.New,"item already exists");
    _;
  }
  // Define a modifier that checks if an item.state of a upc is Harvested
  modifier harvested(uint _upc) {
    require(items[_upc].itemState == State.Harvested," This state is not valid, should be Harvested");
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Processed
  modifier processed(uint _upc) {
    require(items[_upc].itemState == State.Processed," This state is not valid, should be Processed");
    _;
  }
  
  // Define a modifier that checks if an item.state of a upc is Packed
  modifier packed(uint _upc) {
    require(items[_upc].itemState == State.Packed," This state is not valid, should be Packed");

    _;
  }

  // Define a modifier that checks if an item.state of a upc is ForSale
  modifier forSale(uint _upc) {
    require(items[_upc].itemState == State.ForSale," This state is not valid, should be ForSale");
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Sold
  modifier sold(uint _upc) {
    require(items[_upc].itemState == State.Sold," This state is not valid, should be Sold");
    _;
  }
  
  // Define a modifier that checks if an item.state of a upc is Shipped
  modifier shipped(uint _upc) {
    require(items[_upc].itemState == State.Shipped," This state is not valid, should be Shipped");
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Received
  modifier received(uint _upc) {
    require(items[_upc].itemState == State.Received," This state is not valid, should be Received");
    _;
  }

  // Define a modifier that checks if an item.state of a upc is Purchased
  modifier purchased(uint _upc) {
    require(items[_upc].itemState == State.Purchased," This state is not valid, should be Purchased");
    _;
  }

  // In the constructor set 'owner' to the address that instantiated the contract
  // and set 'sku' to 1
  // and set 'upc' to 1
  constructor() public payable {
    // owner = msg.sender;
    sku = 1;
    upc = 1;
  }

  // Define a function 'kill' if required
  function kill() public {
    if (msg.sender == owner()) {
      selfdestruct(makePayable(owner()));
    }
  }

  // Define a function 'harvestItem' that allows a farmer to mark an item 'Harvested'
  function harvestItem(uint _upc,
    address _originFarmerID,
    string memory _originFarmName,
    string memory _originFarmInformation,
    string memory  _originFarmLatitude,
    string memory  _originFarmLongitude,
    string memory  _productNotes
  )
    public
    onlyFarmer
    newitem(_upc) 
  {
    // Add the new item as part of Harvest
    items[_upc].upc = _upc;
    items[_upc].sku = sku;
    items[_upc].productID = sku + _upc;
    items[_upc].originFarmerID = _originFarmerID;
    items[_upc].ownerID = _originFarmerID;
    items[_upc].originFarmName = _originFarmName;
    items[_upc].originFarmInformation = _originFarmInformation;
    items[_upc].originFarmLatitude = _originFarmLatitude;
    items[_upc].originFarmLongitude = _originFarmLongitude;
    items[_upc].productNotes = _productNotes;
    items[_upc].itemState = State.Harvested;


    // Increment sku
    sku = sku + 1;
    // Emit the appropriate event
    emit Harvested(_upc);
    
  }

  // Define a function 'processtItem' that allows a farmer to mark an item 'Processed'
  function processItem(uint _upc) 
		public harvested(_upc) 
		onlyItemOwnerOrOwner(_upc)
		onlyFarmer
  {
    // Update the appropriate fields
    items[_upc].itemState = State.Processed;
    // Emit the appropriate event
    emit Processed(_upc);
    
  }

  // Define a function 'packItem' that allows a farmer to mark an item 'Packed'
  function packItem(uint _upc) public 
  // Call modifier to check if upc has passed previous supply chain stage
    processed(_upc)
  // Call modifier to verify caller of this function
		onlyItemOwnerOrOwner(_upc)
		onlyFarmer
  {
    // Update the appropriate fields
    items[_upc].itemState = State.Packed;

    // Emit the appropriate event
    emit Packed(_upc);
    
  }

  // Define a function 'sellItem' that allows a farmer to mark an item 'ForSale'
  function sellItem(uint _upc, uint _price) public 
  // Call modifier to check if upc has passed previous supply chain stage
    packed(_upc)
		onlyFarmer
  // Call modifier to verify caller of this function
    onlyItemOwnerOrOwner(_upc)
  {
    // Update the appropriate fields
    items[_upc].productPrice = _price;
    items[_upc].itemState = State.ForSale;
    
    // Emit the appropriate event
    emit ForSale(_upc,_price);
    
  }

  // Define a function 'buyItem' that allows the disributor to mark an item 'Sold'
  // Use the above defined modifiers to check if the item is available for sale, if the buyer has paid enough, 
  // and any excess ether sent is refunded back to the buyer
  function buyItem(uint _upc) public payable 
    // Call modifier to check if upc has passed previous supply chain stage
    forSale(_upc)
    // Call modifer to check if buyer has paid enough
    paidEnough(items[_upc].productPrice)
		// Only distributors are allowed to buy
		onlyDistributor
    // Call modifer to send any excess ether back to buyer
    checkValue(_upc)
  {
    
    // Update the appropriate fields - ownerID, distributorID, itemState
      items[_upc].ownerID = msg.sender;
      items[_upc].distributorID = msg.sender;
      items[_upc].itemState = State.Sold;
    
    // Transfer money to farmer
      address payable farmerAddress = makePayable(items[_upc].originFarmerID);
      farmerAddress.transfer(items[_upc].productPrice);
    
    // emit the appropriate event
    emit Sold(_upc,items[_upc].distributorID);
    
  }

  // Define a function 'shipItem' that allows the distributor to mark an item 'Shipped'
  // Use the above modifers to check if the item is sold
  function shipItem(uint _upc) public 
    // Call modifier to check if upc has passed previous supply chain stage
    sold(_upc)
     
		// Only distributors are allowed to buy
		onlyDistributor

    // Call modifier to verify caller of this function
    onlyItemOwnerOrOwner(_upc)
  {
    // Update the appropriate fields
    items[_upc].itemState = State.Shipped;
    
    // Emit the appropriate event
    emit Shipped(_upc);
    
  }

  // Define a function 'receiveItem' that allows the retailer to mark an item 'Received'
  // Use the above modifiers to check if the item is shipped
  function receiveItem(uint _upc) public 
    // Call modifier to check if upc has passed previous supply chain stage
    shipped(_upc) 
    // Access Control List enforced by calling Smart Contract / DApp
    onlyRetailer
    {
    // Update the appropriate fields - ownerID, retailerID, itemState
      items[_upc].ownerID = msg.sender;
      items[_upc].retailerID = msg.sender;
      items[_upc].itemState = State.Received;
    
    // Emit the appropriate event
    emit Received(_upc,msg.sender);
    
  }

  // Define a function 'purchaseItem' that allows the consumer to mark an item 'Purchased'
  // Use the above modifiers to check if the item is received
  function purchaseItem(uint _upc) public 
    // Call modifier to check if upc has passed previous supply chain stage
    received(_upc)
    
    // Access Control List enforced by calling Smart Contract / DApp
    onlyConsumer
    {
    // Update the appropriate fields - ownerID, consumerID, itemState
      items[_upc].ownerID = msg.sender;
      items[_upc].consumerID = msg.sender;
      items[_upc].itemState = State.Purchased;
    
    // Emit the appropriate event
    emit Purchased(_upc,msg.sender);
    
  }

  // Define a function 'fetchItemBufferOne' that fetches the data
  function fetchItemBufferOne(uint _upc) public view returns (
    uint    itemSKU,
    uint    itemUPC,
    address ownerID,
    address originFarmerID,
    string memory  originFarmName,
    string memory  originFarmInformation,
    string memory  originFarmLatitude,
    string memory originFarmLongitude
  )
  {
  // Assign values to the 8 parameters
    itemSKU = items[_upc].upc;
    itemUPC = items[_upc].sku;
    ownerID = items[_upc].ownerID;
    originFarmerID = items[_upc].originFarmerID;
    originFarmName = items[_upc].originFarmName;
    originFarmInformation = items[_upc].originFarmInformation;
    originFarmLatitude = items[_upc].originFarmLatitude;
    originFarmLongitude = items[_upc].originFarmLongitude;
    
    return (
      itemSKU,
      itemUPC,
      ownerID,
      originFarmerID,
      originFarmName,
      originFarmInformation,
      originFarmLatitude,
      originFarmLongitude
  );
  }

  // Define a function 'fetchItemBufferTwo' that fetches the data
  function fetchItemBufferTwo(uint _upc) public view returns 
  (
  uint    itemSKU,
  uint    itemUPC,
  uint    productID,
  string memory  productNotes,
  uint    productPrice,
  uint    itemState,
  address distributorID,
  address retailerID,
  address consumerID
  ) 
  {
    // Assign values to the 9 parameters
    itemSKU = items[_upc].upc;
    itemUPC = items[_upc].sku;
    productID = items[_upc].productID;
    productNotes = items[_upc].productNotes;
    productPrice = items[_upc].productPrice;
    itemState = uint256(items[_upc].itemState);
    distributorID = items[_upc].distributorID;
    retailerID = items[_upc].retailerID;
    consumerID = items[_upc].consumerID;
    return 
    (
      itemSKU,
      itemUPC,
      productID,
      productNotes,
      productPrice,
      itemState,
      distributorID,
      retailerID,
      consumerID
    );
  }

  function makePayable(address _addr) private pure returns(address payable) {
    return address(uint160(_addr));
  }
}

