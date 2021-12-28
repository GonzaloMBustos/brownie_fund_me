// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

// interfaces only declare functions and their return types, but don't implement them
// interfaces compile down to ABIs (application binary interface)
// interfaces are like a minimalistic view of another contract (basic functions structures)
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";


contract FundMe {

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
	AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
		priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    // payable function says this is a function that can be used to pay
    // every function call has an associated value = amount of eth sent with transaction
    function fund() public payable {
        // let's say minimum funding required is $50
        uint256 minimumUSD = 50 * 10 ** 18;
        // require will REVERT the transaction if requirement is not met
        // REVERT = user will get money back, and will stop executing
        require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more eth");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    // this funding GIVES THE SMART CONTRACT x amount of eth

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (,int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function getConversionRate(uint256 ethAmount) public view returns(uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / (1000000000000000000);
        return ethAmountInUsd;
    }

    // modifiers change the behaviour of a function in a declarative way
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function withdraw() payable onlyOwner public {
        // if we only want the contract admin/owner to be able to withdraw
        // require(msg.sender == owner);
        // this = Contract context
        // balance = balance in ether
        payable(msg.sender).transfer(address(this).balance);
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }

	function getEntranceFee() public view returns (uint256) {
		// minimum USD
		uint256 minimumUSD = 50 * 10**18;
		uint256 price = getPrice();
		uint256 precision = 1 * 10**18;
		return (minimumUSD * precision) / price;
	}

    // 0.00040965780531200
    // integers wrap around on overflow
}
