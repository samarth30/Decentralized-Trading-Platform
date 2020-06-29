pragma solidity ^0.6.3;

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol';

contract DEX{
    
    // checking the state buying or selling
    enum Side{
        BUY,
        SELL
    }
    
    // token structure
    struct Token{
        bytes32 ticker;
        address tokenAddress;
    }
    
    // struct for orders 
    struct Order{
        uint id;
        address trader;
        Side side;
        bytes32 ticker;
        uint amount;
        uint filled;
        uint price;
        uint date;
    }
    
    // token store in front of token string
    mapping(bytes32 => Token) public tokens;
    // token array to store string list of all tokens
    bytes32[] public tokenList;
    //mapping to store the amount of particular token a account have
    mapping(address => mapping(bytes32 => uint)) public traderBalances;
    // mapping to store the orders or selling buying price of particular token
    mapping(bytes32 => mapping(uint => Order[])) public orderBook;
    // admin
    address admin;
    // order id
    uint public nextOrderId;
    // trader id
    uint public nextTradeId;
    
    // DAI
    bytes32 constant DAI = bytes32('DAI');
    
    
    event NewTrade(
        uint tradeId,
        uint orderId,
        bytes32 indexed ticker,
        address indexed trader1,
        address indexed trader2,
        uint amount,
        uint price,
        uint date
        );
    // constructor
    constructor() public {
        admin = msg.sender;
    }
    
    // adding the token only admin can add different uinque tokens to be traded
    function addToken(bytes32 _ticker,address _tokenAddress) onlyAdmin() external{
        tokens[_ticker] = Token(_ticker,_tokenAddress);
        tokenList.push(_ticker);
    }
    
    // deposit a token
    function deposit(uint amount,bytes32 _ticker) external{
        IERC20(tokens[_ticker].tokenAddress).transferFrom(msg.sender,address(this),amount);
        traderBalances[msg.sender][_ticker] += amount;
    }
    
    function withdraw(uint amount,bytes32 _ticker) tokenExist(_ticker) external{
        require(traderBalances[msg.sender][_ticker] >= amount);
        IERC20(tokens[_ticker].tokenAddress).transfer(msg.sender,amount);
        
        traderBalances[msg.sender][_ticker] -= amount;
    }
    
    function createLimitOrder(bytes32 ticker,uint amount,uint price,Side side) tokenIsNotDai(ticker) external{
       
        if(side == Side.SELL){
            require(traderBalances[msg.sender][ticker] >= amount,'the no of ticker is less than 0');
        }else{
            require(traderBalances[msg.sender][DAI]>= amount*price,'you have not enough funds');
        }
        
        Order[] storage orders = orderBook[ticker][uint(side)]; 
        
        orders.push(Order(nextOrderId,msg.sender,side,ticker,amount,0,price,now));
        
        uint i = orders.length - 1;
        while(i>0){
            if(side == Side.BUY && orders[i-1].price > orders[i].price){
                break;
            }
            if(side == Side.SELL && orders[i-1].price < orders[i].price){
                break;
            }
            Order memory order = orders[i-1];
            orders[i-1] = orders[i];
            orders[i] = order;
            i++;
        }
     nextOrderId++;
    }
    // market order
    function createMarketOrder(bytes32 ticker,uint amount,Side side) tokenExist(ticker) tokenIsNotDai(ticker) external{
        // checking the trader has enough amount of ticker
        if(side == Side.SELL){
            require(traderBalances[msg.sender][ticker] >= amount,'the no of ticker is less than amount');
        }
        
        // creating a pointer order so that if you are buying you should see least selling price and if buying then least buying price
        Order[] storage orders = orderBook[ticker][uint(side == Side.BUY ? Side.SELL:Side.BUY)];
        uint i;
        // as filled will be zero at the beginning
        uint remaining = amount;
        // iterate over the loop and tb tk iterate when i is less than orders.lengt and remaining must be greater than 0 when liquidity 
        // finished then loop overs as remaing = 0
        while(i<orders.length && remaining >0){
            // checking how much ticker is remaining or checking liquidity
            uint avaliable = orders[i].amount - orders[i].filled;
            // matching that if remaing greater than the avaliable then whole the fund of ticker or liquidity in the ticker will be equal to matched
            //otherwise if remaining less than the avaliable then the liquidity will not be overed the token will be selled without any liquidy overed
            uint matched = (remaining > avaliable ? avaliable : remaining);
            remaining -= matched; // actual liquidity
            orders[i].filled += matched; // decrese the liquidity by increading filled
            emit NewTrade(
                nextTradeId,
                orders[i].id,
                ticker, 
                orders[i].trader,// who created the order in order book
                msg.sender, // who is buying in the market
                matched, // amount will be equal to the liquidity we want 
                orders[i].price, // price
                now
                );
            // we need to update the token traderBalances
            if(side == Side.SELL){ 
                traderBalances[msg.sender][ticker] -= matched;
                traderBalances[msg.sender][DAI] += matched * orders[i].price;
                traderBalances[orders[i].trader][ticker] += matched;
                traderBalances[orders[i].trader][DAI] -= matched * orders[i].price; 
            }
            if(side == Side.BUY){
                require(traderBalances[msg.sender][DAI] > matched * orders[i].price,'dai balance too low');
                 traderBalances[msg.sender][ticker] += matched;
                traderBalances[msg.sender][DAI] -= matched * orders[i].price;
                traderBalances[orders[i].trader][ticker] -= matched;
                traderBalances[orders[i].trader][DAI] += matched * orders[i].price;
            }
            nextTradeId++;
            i++;
        }
        i = 0;
        // cheing the orders wholse liquidity is completey finished then they should be deleted
        // so we will interate i so when ever the the filled will be equal to amount then the for loop will be active 
        while(i<orders.length && orders[i].filled == orders[i].amount){
            for(uint j=i;j<orders.length-1;j++){
                orders[j] = orders[j+1];
            }
            orders.pop();
            i++; 
        }
    }
    
    modifier tokenIsNotDai(bytes32 ticker) {
        require(ticker != bytes32('DAI'));
        _;
    }
    
    modifier tokenExist(bytes32 _ticker){
        require(tokens[_ticker].tokenAddress != address(0));
        _;
    }
    
    modifier onlyAdmin(){
        require(msg.sender == admin,"you are not the admin");
        _;
    }
}



























