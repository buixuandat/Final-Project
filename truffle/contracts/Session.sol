pragma solidity ^0.4.17;
pragma experimental ABIEncoderV2;
import './Main.sol';


contract Session {
    // Variable to hold Main Contract Address when create new Session Contract
    address public mainContract;
    // Variable to hold Main Contract instance to call functions from Main
    Main MainContract;
    enum SessionState{created, started, stoped, closed}

    // TODO: Variables
    struct IPricingSession{
        string name;
        string description;
        string[] images;
        uint256 proposedPrice;
        SessionState state;
    }

    struct ISessionParticipant{
        address account;
        uint256 givenPrice;
        uint256 deviation;
    }

    IPricingSession private pricingSession;
    address public admin;
    address[] private participantAccounts;
    mapping(address => ISessionParticipant) sessionParticipant;
    

    modifier onlyAdmin(){
        require(admin == msg.sender);
        _;
    }

    event started();
    event stoped();
    event givenPriceUpdated(address account, uint256 givenPrice, uint256 proposedPrice);
    event finalPriceUpdated (uint256 finalPrice);


    function Session(address _mainContract, string _productName, string _productDescription, string[] memory _productImages
        // Other arguments
    ) public {

        // Get Main Contract instance
        mainContract = _mainContract;
         MainContract =  Main(_mainContract);
        
        // TODO: Init Session contract
        require (MainContract.admin() == msg.sender);

        pricingSession.name = _productName;
        pricingSession.description = _productDescription;
        pricingSession.images = _productImages;
        pricingSession.state = SessionState.created;

        admin = msg.sender;

        
        // Call Main Contract function to link current contract.
        MainContract.addSession(address(this));
    }

    // TODO: Functions
    function startPricingSession() onlyAdmin() public{
        require(pricingSession.state == SessionState.created || pricingSession.state == SessionState.stoped);

        pricingSession.state = SessionState.started;
        emit started();
    }

    function stopPricingSession() onlyAdmin() public{
        require(pricingSession.state == SessionState.started);

        pricingSession.state = SessionState.stoped;
        emit stoped();
    }

    function setGivenPrice(uint256 _price) public{
        require(pricingSession.state == SessionState.started);

        bool isRegisted = MainContract.checkRegisterAccount(msg.sender);
        require (isRegisted);

        // update participant
        if(sessionParticipant[msg.sender].account == address(0)){
            sessionParticipant[msg.sender].account = msg.sender;

            participantAccounts.push(msg.sender);

            MainContract.updateSessionNumber(msg.sender);
        }
            
        sessionParticipant[msg.sender].givenPrice = _price;
        
        pricingSession.proposedPrice = calculatePrice();

        emit givenPriceUpdated(msg.sender, _price, pricingSession.proposedPrice);
    }

    function setFinalPrice(uint256 _price) onlyAdmin public{
        require(pricingSession.state != SessionState.closed);

        pricingSession.state = SessionState.closed;
        pricingSession.proposedPrice = _price;

        for(uint256 i = 0; i < participantAccounts.length; i++){
            // in session
            ISessionParticipant storage itemParticipant = sessionParticipant[participantAccounts[i]];
                      
            uint256 numerator = abs(_price - itemParticipant.givenPrice);
            uint256 denominator = _price;

            uint256 deviation = numerator  * 100 / denominator;
            itemParticipant.deviation = deviation;

            // in main
            uint256 sessionNumber = MainContract.getSessionNumber(participantAccounts[i]);           
            uint256 deviationCurrent = MainContract.getDeviation(participantAccounts[i]);

            numerator = deviationCurrent * sessionNumber + deviation;
            denominator = sessionNumber + 1;

            uint256 newDeviation = numerator / denominator;
            MainContract.updateDeviation(participantAccounts[i], newDeviation);
        }

        
        emit finalPriceUpdated(_price);
    }

    function abs(uint256 x) private pure returns (uint256) {
        return x >= 0 ? x : -x;
    }

    function calculatePrice() private returns(uint256){
        uint256 n = participantAccounts.length;
        uint256 numerator = 0;
        uint256 denominator = 0;

        for(uint256 i = 0; i < n; i++){
            uint256 deviation = MainContract.getDeviation(participantAccounts[i]);
            uint256 pGivenPrice = sessionParticipant[participantAccounts[i]].givenPrice;

            numerator += (pGivenPrice * (100 - deviation));
            denominator += deviation;
        }    

        uint256 proposedPrice = numerator / ((100 * n) - denominator);
        return proposedPrice;
    }

    function updateProductInfo(string _productName, string _productDescription, string[] memory _productImages) onlyAdmin() public{
        pricingSession.name = _productName;
        pricingSession.description = _productDescription;
        pricingSession.images = _productImages;
    }

    function viewParticipantInfo(address _account) view public returns (ISessionParticipant){
        return sessionParticipant[_account];
    }

    function getPricingSession() view public returns(string memory, string memory, string[] memory, uint256, SessionState) {
        return (pricingSession.name, pricingSession.description, pricingSession.images, pricingSession.proposedPrice, pricingSession.state);
    }
}
