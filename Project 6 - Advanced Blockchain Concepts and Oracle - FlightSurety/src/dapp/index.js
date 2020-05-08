import Web3 from "web3";
import appContractArtifact from "../../build/contracts/FlightSuretyApp.json";
import dataContractArtifact from "../../build/contracts/FlightSuretyData.json";
import configArtifact from "./config.json";
import BigNumber from 'bignumber.js';
import dateFormat from 'dateformat';

const App = {
  web3: null,  owner: null, currentUser: null, appContract: null, dataContract: null,

  buyInsurance: async function() {
    const insurancePrice = document.getElementById("insurancePrice").value;
    let amount = web3.toWei(insurancePrice, "ether");
    console.log("Amount in wei:", amount);
    const flightSelect = document.getElementById("flightSelect");
    let flightInfo = flightSelect.options[flightSelect.selectedIndex].value;
    let flightInfoArray = flightInfo.split("-").map(item => item.trim()); // [flight, scheduledDepartureTime, airline]
    console.log("flightInfoArray", flightInfoArray);

    const { buyInsurance } = this.appContract.methods;
    await buyInsurance(flightInfoArray[2], flightInfoArray[0], flightInfoArray[1]).send({ from: this.currentUser, value: amount })
    .on('transactionHash', (hash) => {
      App.fetchInsurances();
    });
  },

  fetchInsurances: function () {
    this.dataContract.getPastEvents('InsuranceBought', {filter: {passenger: this.currentUser}, fromBlock: 0, toBLock: 'latest'}, (err, events) => {
      if (!err) {   
        if (events.length == 0) {
          document.getElementById("insuranceList").innerHTML = "Not found";
        } else {
          document.getElementById("insuranceList").innerHTML = "";
          for (event of events) {
            try {
              let itemNode = document.createElement("li");                 
              let priceEth = web3.fromWei(BigNumber(event.returnValues.price).toNumber(), "ether");
              let textnode = document.createTextNode(event.returnValues.flight + " — " + event.returnValues.passenger + " — " + priceEth + " ETH");         
              itemNode.appendChild(textnode);                              
              document.getElementById("insuranceList").appendChild(itemNode);     
            } catch(err) {
              console.log(err);
            }
          }
        }
      }
    });
  },

  registerAirlne: async function() {
    const address = document.getElementById("airlineAddress").value;
    const name = document.getElementById("airlineName").value;

    const { registerAirline } = this.appContract.methods;
    await registerAirline(address, name).send({ from: this.currentUser })
    .on('transactionHash', (hash) => {
      App.fetchAirlines();
    });
  },

  fetchFlights: async function() {
    this.appContract.getPastEvents('FlightRegistered', {fromBlock: 0, toBLock: 'latest'}, (err, events) => {
      if (!err) {   
        if (events.length == 0) {
          document.getElementById("flightList").innerHTML = "Not found";
          document.getElementById("flightSelect").innerHTML = "";
        } else {
          document.getElementById("flightList").innerHTML = "";
          document.getElementById("flightSelect").innerHTML = "";
          for (event of events) {
            let itemNode = document.createElement("li");          
            let departure = App.getFormattedDate(event.returnValues.scheduledDepartureTime);      
            let arrival = App.getFormattedDate(event.returnValues.scheduledArrivalTime);      
            let textnode = document.createTextNode(event.returnValues.flight + " — " 
              + departure + " (" + event.returnValues.departureAirport + ") — " 
              + arrival + " (" + event.returnValues.arrivalAirport + ") — " 
              + App.getShortAddress(event.returnValues.airline));         
            itemNode.appendChild(textnode);                              
            document.getElementById("flightList").appendChild(itemNode);     

            let option = document.createElement("option");                 
            option.text = event.returnValues.flight + " | " 
              + departure + " (" + event.returnValues.departureAirport + ") | " 
              + arrival + " (" + event.returnValues.arrivalAirport + ") | " 
              + App.getShortAddress(event.returnValues.airline);
            option.value = event.returnValues.flight + "-" + event.returnValues.scheduledDepartureTime + "-" + event.returnValues.airline;
            document.getElementById("flightSelect").add(option); 
          }  
        }
      }
    });
  },

  getIsOperational: async function() {
    const { isOperational } = this.appContract.methods;
    const resultOperational = await isOperational().call();
    console.log("Operational:", resultOperational);
    const operationalElement = document.getElementById("operational");
    operationalElement.innerHTML = resultOperational ? "Operational" : "Not operational";
    operationalElement.className = resultOperational ? "operational" : "notOperational";
  },

  getIsAirline: async function() {
    let airlineElement = document.getElementById("isAirline");
    airlineElement.innerHTML = "";
    const { isAirline } = this.appContract.methods;
    const resultIsAirline = await isAirline().call({from: this.currentUser});
    console.log("Is Airline:", resultIsAirline);
    airlineElement = document.getElementById("isAirline");
    airlineElement.innerHTML = resultIsAirline ? "(airline)" : "(not an airline)";
    airlineElement.className = resultIsAirline ? "airline" : "notAirline";
  },

  fetchAirlines: function () {
    this.dataContract.getPastEvents('AirlineRegistered', {fromBlock: 0, toBLock: 'latest'}, (err, events) => {
        if (!err) {   
          document.getElementById("airlinesList").innerHTML = "";
          for (event of events) {
            var itemNode = document.createElement("li");                 
            var textnode = document.createTextNode(event.returnValues.name + " — " + event.returnValues.account);         
            itemNode.appendChild(textnode);                              
            document.getElementById("airlinesList").appendChild(itemNode);     
          }
        }
    });
  },
  getOwner: async function() {
    const { contractOwner } = this.appContract.methods;
    this.owner = await contractOwner().call();
    console.log("Owner:", this.owner);
    const ownerElement = document.getElementById("owner");
    ownerElement.innerHTML = this.owner;
  },

  sendFunds: async function() {
    const fundsToSend = parseInt(document.getElementById("fundsToSend").value);
    let amount = web3.toWei(fundsToSend, "ether");

    const { fund } = this.appContract.methods;
    await fund().send({ from: this.currentUser, value: amount });
  },

  registerFlight: async function() {
    const flight = document.getElementById("flightNumber").value;
    const departureTime = document.getElementById("departureTime").value;
    const arrivalTime = document.getElementById("arrivalTime").value;
    const origAirport = document.getElementById("departureAirport").value;
    const destAirport = document.getElementById("arrivalAirport").value;

    let departureTimestamp; 
    let arrivalTimestamp;
    try {
      departureTimestamp = Math.trunc(new Date(departureTime).getTime() / 1000);
      console.log("departure", departureTimestamp);
    } catch(e) {}
    try {
      arrivalTimestamp = Math.trunc(new Date(arrivalTime).getTime() / 1000);
      console.log("arrival", arrivalTimestamp);
    } catch(e) {}

    const { registerFlight } = this.appContract.methods;
    await registerFlight(flight, departureTimestamp, arrivalTimestamp, origAirport, destAirport).send({ from: this.currentUser })
    .on('transactionHash', (hash) => {
      App.fetchFlights();
    });
  },

  requestFlightStatus: async function() {
    const flightSelect = document.getElementById("flightSelect");
    let flightInfo = flightSelect.options[flightSelect.selectedIndex].value;
    let flightInfoArray = flightInfo.split("-").map(item => item.trim()); 
    console.log("flightInfoArray", flightInfoArray);
    const { fetchFlightStatus } = this.appContract.methods;
    await fetchFlightStatus(flightInfoArray[2], flightInfoArray[0], flightInfoArray[1]).send({ from: this.currentUser });
  },

  getShortAddress: function(address) {
    return address.substring(0, 6) + "..." + address.substring(address.length-4);
  },

  getFormattedDate: function(solidityTimestamp) {
    return dateFormat(solidityTimestamp * 1000, "yyyy-mm-dd HH:MM");
  },

  getFlightStatusInfo: async function () {
    const flightSelect = document.getElementById("flightSelect");
    let flightInfo = flightSelect.options[flightSelect.selectedIndex].value;
    let flightInfoArray = flightInfo.split("-").map(item => item.trim()); 
    const { getFlightStatusInfo } = this.appContract.methods;
    let { statusCode, updateTimestamp } = await getFlightStatusInfo(flightInfoArray[2], flightInfoArray[0], flightInfoArray[1]).call();
    let status = BigNumber(statusCode).toNumber();
    console.log("statusCode:", status, "updateTimestamp:", BigNumber(updateTimestamp).toNumber());
    let lastUpdate = new Date(BigNumber(updateTimestamp).toNumber() * 1000);
    let statusDescription = "UNKNOWN";
    switch(status) {
      case 0: statusDescription = "UNKNOWN"; break;
      case 10: statusDescription = "ON TIME"; break;
      case 20: statusDescription = "LATE (AIRLINE)"; break;
      case 30: statusDescription = "LATE (WEATHER)"; break;
      case 40: statusDescription = "LATE (TECHNICAL)"; break;
      case 50: statusDescription = "LATE (OTHER)"; break;
    }
    const flightStatusElement = document.getElementById("flightStatus");
    flightStatusElement.value = statusDescription;
    const lastUpdateElement = document.getElementById("lastUpdate");
    lastUpdateElement.innerHTML = "Last update: " + lastUpdate.toString();
  },

  claimCompensation: async function() {
    const flightSelect = document.getElementById("flightSelect");
    let flightInfo = flightSelect.options[flightSelect.selectedIndex].value;
    let flightInfoArray = flightInfo.split("-").map(item => item.trim());

    const { claimCompensation } = this.appContract.methods;
    await claimCompensation(flightInfoArray[2], flightInfoArray[0], flightInfoArray[1]).send({from: this.currentUser})
    .on('transactionHash', (hash) => {
      App.checkCredits();
    });
  },

  checkCredits: async function() {
    const { getAmountToBeReceived } = this.appContract.methods;
    const creditsAmount = await getAmountToBeReceived().call({from: this.currentUser});
    console.log("creditsAmount:", BigNumber(creditsAmount).toNumber());
    let creditsElement = document.getElementById("credits");
    creditsElement.value = web3.fromWei(BigNumber(creditsAmount).toNumber(), "ether") + " ETH";
  },

  withdrawCredits: async function() {
    const { withdrawCompensation } = this.appContract.methods;
    await withdrawCompensation().send({ from: this.currentUser })
    .on('transactionHash', (hash) => {
      App.checkCredits();
    });
  },

  start: async function() {
    const { web3 } = this;
    try {
      let network = Object.keys(configArtifact)[0];
      this.dataContract = new web3.eth.Contract(
        dataContractArtifact.abi,
        configArtifact[network].dataAddress,
      );
      console.log("DataContract:", this.dataContract);

      console.log("appAddress:", configArtifact[network].appAddress);
      this.appContract = new web3.eth.Contract(
        appContractArtifact.abi,
        configArtifact[network].appAddress,
      );
      const accounts = await web3.eth.getAccounts();
      this.currentUser = accounts[0];
      const currentUserElement = document.getElementById("currentUser");
      currentUserElement.innerHTML = this.currentUser;
      let self = this;
      let accountRefreshInterval = setInterval(async function() {
        let currentAccounts = await web3.eth.getAccounts();
        if (currentAccounts[0] !== self.currentUser) {
          self.currentUser = currentAccounts[0];
          const currentUserElement = document.getElementById("currentUser");
          currentUserElement.innerHTML = self.currentUser;
          self.getIsAirline();
        }
      }, 100);      
      this.getOwner();
      this.getIsOperational();
      this.getIsAirline();
      this.fetchAirlines();
      this.fetchFlights(); 
      this.fetchInsurances();
    } catch (error) {
      console.error("Impossible to connect on chain.", error);
    }
  }

};

window.App = App;

window.addEventListener("load", function() {
  if (window.ethereum) {
    App.web3 = new Web3(window.ethereum);
    window.ethereum.enable();
  } else {
    console.warn(
      "No web3 detected",
    );
     App.web3 = new Web3(
      new Web3.providers.HttpProvider("http://127.0.0.1:8545"),
    );
  }

  App.start();
});
