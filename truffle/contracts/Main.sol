pragma solidity ^0.4.17;
pragma experimental ABIEncoderV2;

contract Main {

    // Structure to hold details of Bidder
    struct IParticipant{ 
        address account;
        string fullname;
        string email;
        uint256 nSessions;
        uint256 deviation;
    }
    
    IParticipant[] private registerParticipants;
    address[] private pricingSessions; 
    address public admin;

    modifier onlyAdmin(){
        require(msg.sender == admin);
        _;
    }

    modifier onlySession(){
        address pricingSession;
        for(uint256 i = 0; i < pricingSessions.length; i++){
            if(pricingSessions[i] == msg.sender)
                pricingSession = pricingSessions[i];
        }
        require(pricingSession == msg.sender);
        _;
    }

    function Main() public {
        admin = msg.sender;
    }


    // Add a Session Contract address into Main Contract. Use to link Session with Main
    function addSession(address _session) public {
        pricingSessions.push(_session);
    }

    function register(string _fullName, string _email) public {     
        IParticipant storage participant = getParticipant(msg.sender);  
        require(participant.account != msg.sender);
            
        registerParticipants.push(IParticipant(msg.sender, _fullName, _email, 0, 0));
    }

    function updateParticipant(string _fullName, string _email) public{
        for(uint256 i = 0; i < registerParticipants.length; i++)
        {
            if(msg.sender == registerParticipants[i].account)
            {
                IParticipant storage participant = registerParticipants[i];
                participant.email = _email;
                participant.fullname = _fullName;
            }
        }        
    }

    function checkRegisterAccount(address _account) view public returns(bool){
        for(uint256 i = 0; i < registerParticipants.length; i++)
        {
            if(_account == registerParticipants[i].account)
                return true;
        }
        return false;
    }

    function updateSessionNumber(address _account) onlySession public {
        IParticipant storage participant = getParticipant(_account);
        participant.nSessions += 1;
    }

    function updateDeviation(address _account, uint256 _deviation) onlySession public {
        IParticipant storage participant = getParticipant(_account);
        participant.deviation = _deviation;
    }

    function getParticipant(address _account) internal returns (IParticipant storage){
        for(uint256 i = 0; i < registerParticipants.length; i++)
        {
            if(_account == registerParticipants[i].account)
                return registerParticipants[i];
        }
    }

     // View functions
    function getDeviation(address _account) view public returns (uint256){
         IParticipant memory participant = getParticipant(_account);
         return participant.deviation;
    }

    function getSessionNumber(address _account) view public returns(uint256){
        IParticipant memory participant = getParticipant(_account);
         return participant.nSessions;
    }

    function participants (address _account) view public returns(IParticipant){
        IParticipant memory participant = getParticipant(_account);
        return participant;
    }

    function nParticipants() view public returns (uint256){
        return registerParticipants.length;
    }

    function iParticipants (uint256 _index) view public returns(address){
        require(_index < registerParticipants.length);
       
        return registerParticipants[_index].account;       
    }

    function nSessions() view public returns (uint256){
        return pricingSessions.length;
    }

    function sessions(uint256 _index) view public returns(address){
        require(_index < pricingSessions.length);
        return pricingSessions[_index];
    } 
}
