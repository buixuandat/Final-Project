pragma solidity ^0.4.17;
pragma experimental ABIEncoderV2;
import './Main.sol';

// Interface of Main contract to call from Session contract
// contract Main {
//     struct IParticipant{ 
//         address Account;
//         string FullName;
//         string Email;
//         uint256 SessionNumber;
//         uint256 Deviation;
//     }

//     function addSession(address session) public {}
//     function participants (address _account) view public returns(IParticipant){}
//     function updateSessionNumber2() public returns(address) {}

// }

contract Session {
    // Variable to hold Main Contract Address when create new Session Contract
    address public mainContract;
    // Variable to hold Main Contract instance to call functions from Main
    Main MainContract;
    enum SessionState{created, started, stoped, closed}

    // TODO: Variables
    struct IPricingSession{
        string ProductName;
        string ProductDescription;
        string[] ProductImages;
        uint256 ProposedPrice;
        uint256 FinalPrice;
        SessionState State;
    }

    struct ISessionParticipant{
        address Account;
        uint256 GivenPrice;
        uint256 Deviation;
    }

    IPricingSession public pricingSession;
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
        pricingSession.ProductName = _productName;
        pricingSession.ProductDescription = _productDescription;
        pricingSession.ProductImages = _productImages;
        pricingSession.State = SessionState.created;

        admin = msg.sender;

        
        // Call Main Contract function to link current contract.
        MainContract.addSession(address(this));
    }

    // TODO: Functions
    function startPricingSession() onlyAdmin() public{
        require(pricingSession.State == SessionState.created || pricingSession.State == SessionState.stoped);

        pricingSession.State = SessionState.started;
        emit started();
    }

    function stopPricingSession() onlyAdmin() public{
        require(pricingSession.State == SessionState.started);

        pricingSession.State == SessionState.stoped;
        emit stoped();
    }

    function setGivenPrice(uint256 _price) public{
       bool isRegisted = MainContract.checkRegisterAccount(msg.sender);
       require (isRegisted);

        // update participant
        if(sessionParticipant[msg.sender].Account == address(0)){
            sessionParticipant[msg.sender].Account = msg.sender;

            participantAccounts.push(msg.sender);

            MainContract.updateSessionNumber(msg.sender);
        }
            
        sessionParticipant[msg.sender].GivenPrice = _price;
        
        pricingSession.ProposedPrice = calculatePrice();

        emit givenPriceUpdated(msg.sender, _price, pricingSession.ProposedPrice);
    }

    function setFinalPrice(uint256 _price) onlyAdmin public{
        require(pricingSession.State != SessionState.closed);

        pricingSession.State = SessionState.closed;
        pricingSession.FinalPrice = _price;

        for(uint256 i = 0; i < participantAccounts.length; i++){
            // in session
            ISessionParticipant storage itemParticipant = sessionParticipant[participantAccounts[i]];
                      
            uint256 numerator = abs(_price - itemParticipant.GivenPrice);
            uint256 denominator = _price;

            uint256 deviation = numerator / denominator * 100;
            itemParticipant.Deviation = deviation;

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
            uint256 pGivenPrice = sessionParticipant[participantAccounts[i]].GivenPrice;

            numerator += (pGivenPrice * (100 - deviation));
            denominator += deviation;
        }    

        uint256 proposedPrice = numerator / ((100 * n) - denominator);
        return proposedPrice;
    }

    function updateProductInfo(string _productName, string _productDescription, string[] memory _productImages) onlyAdmin() public{
        pricingSession.ProductName = _productName;
        pricingSession.ProductDescription = _productDescription;
        pricingSession.ProductImages = _productImages;
    }

    function viewParticipantInfo(address _account) view public returns (ISessionParticipant){
        return sessionParticipant[_account];
    }
}
