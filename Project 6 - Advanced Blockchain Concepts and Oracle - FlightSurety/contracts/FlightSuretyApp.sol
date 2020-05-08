pragma solidity >=0.5.0 <0.6.0;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {

    using SafeMath for uint256; 
    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    uint256 private constant AIRLINES_THRESHOLD = 4;
    uint256 public constant MAX_INSURANCE_COST = 1 ether;
    uint256 public constant INSURANCE_RETURN_PERCENTAGE = 150;
    uint256 public minimumFunds = 10 ether; 

    address public contractOwner;          // Account used to deploy contract

    struct Flight {
        bool isRegistered;
        uint8 statusCode;
        uint256 updatedTimestamp;
        uint256 depTime; 
        uint256 arrivalTime;       
        address airline;
        string depAirport;
        string arrAirport;
    }

    mapping(address => mapping(address => bool)) private voters;
    mapping(address => uint256) private votesNumber;
    mapping(bytes32 => Flight) private flights;
    FlightSuretyData internal flightSuretyData;


    event FlightReg(
        address indexed airline, 
        string indexed indexedFlight, 
        string flight, 
        uint256 depTime, 
        uint256 arrivalTime, 
        string depAirport, 
        string arrAirport
    );

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() {
         // Modify to call data contract's status
        require(isOperational(), "Contract is currently not operational");  
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner() {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */
    constructor(address payable dataContract) public {
        contractOwner = msg.sender;
        flightSuretyData = FlightSuretyData(dataContract);
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational() public view returns(bool) {
        return flightSuretyData.isOperational();  
    }

    function isAirline() public view returns(bool) {
        return flightSuretyData.isAirline(msg.sender);  
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

  
    /**
    * @dev Update the minimum funds required for an airline to operate the contract
    *      Can only be called by the contract owner
    */    
    function updateMinimumFunds(uint256 _Amount) external requireContractOwner requireIsOperational {
        minimumFunds = _Amount;
    }

    function vote(address _airline, address _caller) internal {
        if (voters[_airline][_caller] == false)  {   // Count vote only once per airline
            voters[_airline][_caller] = true;
            votesNumber[_airline] = votesNumber[_airline].add(1);
        }
    }

   /**
    * @dev Add an airline to the registration queue
    *
    */   
    function registerAirline(address account, string calldata name) external requireIsOperational returns(bool success, uint256 votes) {
        
        require(!flightSuretyData.isAirline(account), "Airline already registered");
        require(flightSuretyData.isFunded(msg.sender), "Found first");
        require(flightSuretyData.isAirline(msg.sender), "Sender need to be an Airline");
        success = false;
        votes = 0;
        uint256 numAirlines = flightSuretyData.getNumAirlines();
        if (numAirlines < AIRLINES_THRESHOLD) {
            flightSuretyData.registerAirline(account, name);
            success = true;
        } else {
            uint256 numVotesNeededx100 = numAirlines.mul(100).div(2);  
            vote(account, msg.sender);
            votes = votesNumber[account];
            if (votes.mul(100) >= numVotesNeededx100) { 
                flightSuretyData.registerAirline(account, name);
                success = true;
            }
        }
    }

   /**
    * @dev Update the name of the airline (optional)
    *
    */   
    function updateAirlineName(string calldata newName) external requireIsOperational {
        require(flightSuretyData.isAirline(msg.sender), "Sender need to be an Airline");
        require(bytes(newName).length == 0, "Name is required");
        flightSuretyData.updateAirlineName(msg.sender, newName);
    }

   /**
    * @dev Send funds to the contract, to be called by the airlines
    *
    */   
    function fund() external payable requireIsOperational {
        require(flightSuretyData.isAirline(msg.sender), "Sender need to be an Airline");
        require(msg.value >= minimumFunds, "Not enough funds");
        flightSuretyData.fund.value(msg.value)(msg.sender);
    }
 

   /**
    * @dev Register a future flight for insuring.
    *
    */  
    function registerFlight(string calldata flight, 
                    uint256 depTime, 
                    uint256 arrivalTime,
                    string calldata depAirport, 
                    string calldata arrAirport) external requireIsOperational {
        require(depTime > block.timestamp, "Flight need to be in the future");
        require(flightSuretyData.isFunded(msg.sender), "Sender has not been funded yet");
        require(flightSuretyData.isAirline(msg.sender), "Only airlines can do it");
        require(arrivalTime > depTime, "Arrival should be after departure");
        bytes32 key = getFlightKey(msg.sender, flight, depTime);
        flights[key] = Flight(
            true, 
            STATUS_CODE_UNKNOWN, 
            block.timestamp, 
            depTime, 
            arrivalTime, 
            msg.sender, 
            depAirport, 
            arrAirport
        );
        emit FlightReg(msg.sender, flight, flight, depTime, arrivalTime, depAirport, arrAirport);
    }
    
   /**
    * @dev Called after oracle has updated flight status
    *
    */  
    function processFlightStatus(address airline, string memory flight, uint256 depTime, uint8 statusCode) internal {
        bytes32 key = getFlightKey(airline, flight, depTime);
        flights[key].updatedTimestamp = block.timestamp;
        flights[key].statusCode = statusCode;
    }

   /**
    * @dev Get the current status code and its update timestamp
    *
    */  
    function getFlightStatusInfo(address airline, string calldata flight, uint256 depTime) external view returns(uint256 statusCode, uint256 updateTimestamp) {
        bytes32 key = getFlightKey(airline, flight, depTime);
        return (flights[key].statusCode, flights[key].updatedTimestamp);
    }

   /**
    * @dev Generate a request for oracles to fetch flight information
    *
    */  
    function fetchFlightStatus(address airline, string calldata flight, uint256 depTime) external requireIsOperational {
        uint8 index = getRandomIndex(msg.sender);
        // Generate a unique key for storing the request
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, depTime));
        oracleResponses[key] = ResponseInfo({requester: msg.sender, isOpen: true});
        emit OracleRequest(index, airline, flight, depTime);
    } 

   /**
    * @dev Buy insurance for a flight
    *
    */  
    function buyInsurance(address airline, string calldata flight, uint256 depTime) external payable requireIsOperational {
        require(msg.value <= MAX_INSURANCE_COST, "Value sent is above maximum allowed");
         require(!flightSuretyData.isAirline(msg.sender), "It not permited to Airlines buy");
        require(block.timestamp < depTime, "Buy before schedule departure");
        bytes32 key = getFlightKey(airline, flight, depTime);
        require(flights[key].isRegistered == true, "Flight not registered");
        flightSuretyData.buy.value(msg.value)(msg.sender, airline, flight, depTime);
    }

   /**
    * @dev Claim compensation for a delayed flight. If it is legitimate claim, proper credit is added 
    *      to all insurees that bought insurance for that flight
    *
    */  
    function claimCompensation(address airline, string calldata flight, uint256 depTime) external requireIsOperational {
        bytes32 key = getFlightKey(airline, flight, depTime);
        require(flights[key].statusCode == STATUS_CODE_LATE_AIRLINE, "This status not fit the requirement");
        require(flights[key].updatedTimestamp > flights[key].arrivalTime, "Claim not allowed yet, flight status not up to date");
        require(block.timestamp > flights[key].arrivalTime, "Claim not allowed yet, flight may still get on schedule");
        flightSuretyData.creditInsurees(INSURANCE_RETURN_PERCENTAGE, airline, flight, depTime);
    }

   /**
    * @dev Allow the insuree to withdraw the credits
    *
    */  
    function withdrawCompensation() external requireIsOperational {
        require(flightSuretyData.getAmountToBeReceived(msg.sender) > 0, "No compensation to be received");
        flightSuretyData.pay(msg.sender);
    }

   /**
    * @dev Get the amount paid by the insuree as insurance for a flight
    *
    */  
    function getAmountPaidByInsuree(address airline, string calldata flight, uint256 depTime) external view returns(uint256) {
        bytes32 key = getFlightKey(airline, flight, depTime);
        require(flights[key].isRegistered == true, "Flight not registered");
        return flightSuretyData.getAmountPaidByInsuree(msg.sender, airline, flight, depTime);
    }

   /**
    * @dev Show the credits available for the insuree (caller)
    *
    */  
    function getAmountToBeReceived() external view returns(uint256) {
        return flightSuretyData.getAmountToBeReceived(msg.sender);
    }

// region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;    

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;


    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;        
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, depTime)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, string flight, uint256 depTime, uint8 status);

    event OracleReport(address airline, string flight, uint256 depTime, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 depTime);
    event OracleRegistered(address account, uint8[3] indexes);


    // Register an oracle with the contract
    function registerOracle() external payable {
        require(!oracles[msg.sender].isRegistered, "Oracle already registered");
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({ isRegistered: true, indexes: indexes });
        emit OracleRegistered(msg.sender, indexes);
    }

    function getMyIndexes() view external returns(uint8[3] memory) {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");
        return oracles[msg.sender].indexes;
    }

    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse(uint8 index, address airline, string calldata flight, uint256 depTime, uint8 statusCode) external {
        require((oracles[msg.sender].indexes[0] == index) 
                || (oracles[msg.sender].indexes[1] == index) 
                || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");


        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, depTime)); 
        require(oracleResponses[key].isOpen, "Flight or scheduled departure time do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, depTime, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

            emit FlightStatusInfo(airline, flight, depTime, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, depTime, statusCode);
        }
    }


    function getFlightKey(address airline, string memory flight, uint256 depTime) pure internal returns(bytes32) {
        return keccak256(abi.encodePacked(airline, flight, depTime));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes(address account) internal returns(uint8[3] memory) {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);
        
        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex(address account) internal returns (uint8) {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

// endregion
}   

// Interface to the data contract FlightSuretyData.sol
interface FlightSuretyData {
    function isOperational() external view returns(bool);
    function registerAirline(address airline, string calldata name) external;
    function getNumAirlines() external view returns(uint256);
    function isAirline(address account) external view returns(bool);
    function updateAirlineName(address airline, string calldata newName) external;
    function fund(address airline) external payable;
    function isFunded(address airline) external view returns(bool);
    function getCurrentFunds(address airline) external view returns(uint256);
    function buy(address payable byer, address airline, string calldata flight, uint256 depTime) external payable;
    function getAmountPaidByInsuree(address payable insuree, address airline, string calldata flight, uint256 depTime) external view returns(uint256 amount);    
    function creditInsurees(uint256 percentage, address airline, string calldata flight, uint256 depTime) external;
    function getAmountToBeReceived(address payable insuree) external view returns(uint256 amount);
    function pay(address payable insuree) external;
}