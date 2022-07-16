import { app, h } from 'hyperapp';
import { Link, Route, location } from '@hyperapp/router';
import { Products } from './pages/products';
import { Sidebar } from './pages/sidebar';
import { Participants } from './pages/participants';
import { config } from './config';
import { promisify } from 'util';
import './css/vendor/bootstrap.css';
import './css/vendor/coreui.css';
import './css/index.css';

const Fragment = (props, children) => children;

const Web3 = require('web3');
let web3js;

if (typeof web3 !== 'undefined') {
  web3js = new Web3(web3.currentProvider);
} else {
  web3js = new Web3('http://localhost:7545');
}

import Main from './contracts/Main.json';
import Session from './contracts/Session.json';

const mainContract = new web3js.eth.Contract(Main.abi, config.mainContract);
//conso//le.log(Main.abi);
//console.log(config.mainContract);
var state = {
  count: 1,
  location: location.state,
  products: [],
  dapp: {},
  balance: 0,
  account: 0,
  admin: null,
  profile: null,
  fullname: '',
  email: ''.replace,
  newProduct: {},
  sessions: [],
  currentProductIndex: 0
};



// Functions of Main Contract
const contractFunctions = {
  getAccounts: promisify(web3js.eth.getAccounts),
  getBalance: promisify(web3js.eth.getBalance),

  // TODO: The methods' name is for referenced. Update to match with your Main contract

  // Get Admin address of Main contract
  getAdmin: mainContract.methods.admin().call,
  
  // Get participant by address
  participants: address => mainContract.methods.participants(address).call,

  // Get number of participants
  nParticipants: mainContract.methods.nParticipants().call,

  // Get address of participant by index (use to loop through the list of participants) 
  iParticipants: index => mainContract.methods.iParticipants(index).call,

  // Register new participant
  register: (fullname, email) => mainContract.methods.register(fullname, email).send,
  
  // Get number of sessions  
  nSessions: mainContract.methods.nSessions().call,

  // Get address of session by index (use to loop through the list of sessions) 
  sessions: index => mainContract.methods.sessions(index).call
};

const actions = {
  inputProfile: ({ field, value }) => state => {
    let profile = state.profile || {};
    profile[field] = value;
    return {
      ...state,
      profile
    };
  },

  inputNewProduct: ({ field, value }) => state => {
    let newProduct = state.newProduct || {};
    newProduct[field] = value;
    return {
      ...state,
      newProduct
    };
  },

  createProduct: () => async (state, actions) => {
    let contract = new web3js.eth.Contract(Session.abi, {
      data: Session.bytecode
    });

    //console.log(state);
    await contract
      .deploy({
        arguments: [
          // TODO: Argurment when Deploy the Session Contract
          // It must be matched with Session.sol Contract Constructor
          // Hint: You can get data from `state`
          config.mainContract,
          state.newProduct["name"],
          state.newProduct["description"],
          [state.newProduct["image"]]
        ]
      })
      .send({ from: state.account });

    actions.getSessions();
  },

  selectProduct: i => state => {
    return {
      currentProductIndex: i
    };
  },

  sessionFn: ({action, data}) => async (state, {}) => {
    console.log(action);
    console.log(data);
    console.log(state.currentProductIndex);

    let session = await contractFunctions.sessions(state.currentProductIndex)();
    // Load the session contract on network
    let contract = new web3js.eth.Contract(Session.abi, session);

    switch (action) {
      case 'start':
        //TODO: Handle event when User Start a new session
       await contract.methods.startPricingSession().send({ from: state.account });

        break;
      case 'stop':
        //TODO: Handle event when User Stop a session
        await contract.methods.stopPricingSession().send({ from: state.account });

        break;
      case 'pricing':
        //TODO: Handle event when User Pricing a product
        //The inputed Price is stored in `data`
        await contract.methods.setFinalPrice(data).send({from: state.account });

        break;
     // case 'close':
        //TODO: Handle event when User Close a session
        //The inputed Price is stored in `data`
     //   break;
      case 'proposedPrice':        // include close function
        await contract.methods.setGivenPrice(data).send({from: state.account });

        break;
    }
  },

  location: location.actions,

  getAccount: () => async (state, actions) => {
    
    let accounts = await contractFunctions.getAccounts();
 
    let balance = await contractFunctions.getBalance(accounts[0]);

    let admin = await contractFunctions.getAdmin();

    let profile = await contractFunctions.participants(accounts[0])();
    if(!profile || profile.account.includes('0x000000000000000'))
      profile = {};

    state = actions.setAccount({
      account: accounts[0],
      balance,
      isAdmin: admin === accounts[0],
      profile
    });
  },
  setAccount: ({ account, balance, isAdmin, profile }) => state => {
    return {
      ...state,
      account: account,
      balance: balance,
      isAdmin: isAdmin,
      profile
    };
  },

  getParticipants: () => async (state, actions) => {
    let participants = [];

    // TODO: Load all participants from Main contract.
    // One participant should contain { address, fullname, email, nSession and deviation }

    let participantNummber = await contractFunctions.nParticipants();

    let i = 0;
    while (i < participantNummber){
        let address = await contractFunctions.iParticipants(i)();
        let participant = await contractFunctions.participants(address)();     

        console.log(participant);

        participants.push({address: participant.account,
                          fullname: participant.fullname, email:  participant.email, 
                          nSessions: participant.nSessions, 
                          deviation: participant.deviation});
        i++;
    }

    actions.setParticipants(participants);
  },

  setParticipants: participants => state => {
    return {
      ...state,
      participants: participants
    };
  },

  setProfile: profile => state => {
    return {
      ...state,
      profile: profile
    };
  },

  register: () => async (state, actions) => {
    // TODO: Register new participant
    let result = await contractFunctions.register(state.profile.fullname, state.profile.email)({ from: state.account });

 
    // TODO: And get back the information of created participant
    const profile =  await contractFunctions.participants(state.account)();
//     console.log(profile);
     actions.setProfile(profile);
  },


  getSessions: () => async (state, actions) => {
    // TODO: Get the number of Sessions stored in Main contract
    let nSession = await contractFunctions.nSessions();
    let sessions = [];

    // TODO: And loop through all sessions to get information

    for (let index = 0; index < nSession; index++) {
      // Get session address
      let session = await contractFunctions.sessions(index)();
      // Load the session contract on network
      let contract = new web3js.eth.Contract(Session.abi, session);

      let id = session;

      // TODO: Load information of session.
      // Hint: - Call methods of Session contract to reveal all nessesary information
      //       - Use `await` to wait the response of contract

      let sessionInfo = await contract.methods.getPricingSession().call();

      let name = sessionInfo[0]; // TODO
      let description = sessionInfo[1]; // TODO
      let price = sessionInfo[3]; // TODO
      let image = ''; // TODO
      let status  = sessionInfo[5] == 0 ? "Created" : sessionInfo[5] == 1 ? "Started" : sessionInfo[5] == 2 ? "Stoped" : "Closed";

      if(sessionInfo[2] && sessionInfo[2].length > 0)
        image = sessionInfo[2][0];

      sessions.push({ id, name, description, price, contract, image, status });
    }
    actions.setSessions(sessions);
  },

  setSessions: sessions => state => {
    return {
      ...state,
      sessions: sessions
    };
  },


};



const view = (
  state,
  { getAccount, getParticipants, register, inputProfile, getSessions }
) => {
  return (
    <body
      class='app sidebar-show sidebar-fixed'
      oncreate={() => {
        getAccount();
        getParticipants();
        getSessions();
      }}
    >
      <div class='app-body'>
        <Sidebar
          balance={state.balance}
          account={state.account}
          isAdmin={state.isAdmin}
          profile={state.profile}
          register={register}
          inputProfile={inputProfile}
        ></Sidebar>
        <main class='main d-flex p-3'>
          <div class='h-100  w-100'>
            <Route path='/products' render={Products}></Route>
            <Route path='/participants' render={Participants}></Route>
          </div>
        </main>
      </div>
    </body>
  );
};
const el = document.body;

const main = app(state, actions, view, el);
const unsubscribe = location.subscribe(main.location);
