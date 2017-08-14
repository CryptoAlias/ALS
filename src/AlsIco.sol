pragma solidity ^0.4.11;

contract SafeMath {

    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal returns (uint) {
        require(b > 0);
        uint c = a / b;
        require(a == b * c + a % b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        require(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        require(c >= a && c >= b);
        return c;
    }
}

contract AlsToken {
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address receiver, uint amount) public;
}

contract Owned {

    address private owner;

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function getOwner() public constant returns (String currentOwner) {
        return owner;
    }
}

contract AlsIco is Owned, SafeMath {

    // Crowdsale start time in seconds since epoch.
    // Equivalent to Monday, October 2, 2017 00:00:00 UTC
    uint256 public constant crowdsaleStartTime = 1506902400;

    // Crowdsale end time in seconds since epoch.
    // Equivalent to Monday, October 30, 2017 00:00:00 UTC
    uint256 public constant crowdsaleEndTime = 1509321600;

    uint public amountRaised;
    AlsToken public alsToken;

    event FundTransfer(address backer, uint amount, bool isContribution);

    function AlsIco(address alsTokenAddress) {
        alsToken = AlsToken(alsTokenAddress);
    }

    modifier onlyAfterStart() {
        require(now >= crowdsaleStartTime);
        _;
    }

    modifier onlyBeforeEnd() {
        require(now <= crowdsaleEndTime);
        _;
    }

    // Returns ALS/ETH current price.
    function getPrice() public constant onlyAfterStart onlyBeforeEnd returns (uint256) {

        if (now < (crowdsaleStartTime + 1 days)) {
            // In the first day, 1 ETH buys 1500 ALS.
            return 1500;
        } else if (now < (crowdsaleStartTime + 3 days)) {
            // In the first 3 days, 1 ETH buys 1400 ALS.
            return 1400;
        } else if (now < (crowdsaleStartTime + 6 days)) {
            // In the first 6 days, 1 ETH buys 1300 ALS.
            return 1300;
        } else if (now < (crowdsaleStartTime + 10 days)) {
            // In the first 10 days, 1 ETH buys 1200 ALS.
            return 1200;
        } else if (now < (crowdsaleStartTime + 15 days)) {
            // In the first 15 days, 1 ETH buys 1100 ALS.
            return 1100;
        } else {
            // After the first 15 days, 1 ETH buys 1000 ALS.
            return 1000;
        }
    }

    function () payable onlyAfterStart onlyBeforeEnd {
        uint256 availableTokens = alsToken.balanceOf[this];
        require (availableTokens > 0);

        uint256 etherAmount = msg.value;
        require(etherAmount > 0);

        uint256 price = getPrice();
        uint256 tokenAmount = safeMul(etherAmount, price);

        if (tokenAmount <= availableTokens) {
            amountRaised = safeAdd(amountRaised, etherAmount);

            alsToken.transfer(msg.sender, tokenAmount);
            FundTransfer(msg.sender, etherAmount, true);
        } else {
            uint256 etherToSpend = safeDiv(availableTokens, price);
            amountRaised = safeAdd(amountRaised, etherToSpend);

            alsToken.transfer(msg.sender, availableTokens);
            FundTransfer(msg.sender, etherToSpend, true);

            // Return the rest of the funds back to the caller.
            uint256 amountToRefund = safeSub(etherAmount, etherToSpend);
            msg.sender.send(amountToRefund);
        }
    }

    function withdrawEther(uint _amount) external onlyOwner {
        require(this.balance >= _amount);
        if (owner.send(_amount)) {
            FundTransfer(owner, _amount, false);
        }
    }
}