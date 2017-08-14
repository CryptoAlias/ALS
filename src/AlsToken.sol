pragma solidity 0.4.11;

/**
 * ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {

    // Get the total token supply.
    function totalSupply() public constant returns (uint256 totalSupply);

    // Get the account balance of another account with address _owner.
    function balanceOf(address _owner) public constant returns (uint256 balance);

    // Send _value amount of tokens to address _to.
    function transfer(address _to, uint256 _value) public returns (bool success);

    /* Send _value amount of tokens from address _from to address _to.
     * The transferFrom method is used for a withdraw workflow, allowing contracts to send tokens on your behalf,
     * for example to "deposit" to a contract address and/or to charge fees in sub-currencies; the command should
     * fail unless the _from account has deliberately authorized the sender of the message via the approve mechanism. */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /* Allow _spender to withdraw from your account, multiple times, up to the _value amount.
     * If this function is called again it overwrites the current allowance with _value. */
    function approve(address _spender, uint256 _value) public returns (bool success);

    // Returns the amount which _spender is still allowed to withdraw from _owner.
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    // Event triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Event triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
 * Math operations with safety checks
 */
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

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }
}

/**
 * Standard ERC20 token with Short Hand Attack and approve() race condition mitigation.
 *
 * Based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, SafeMath {

    uint256 private totalSupply;

    /* Actual balances of token holders */
    mapping (address => uint256) private balanceOf;
    mapping (address => mapping (address => uint256)) private allowance;

    /* Interface declaration */
    function isToken() public constant returns (bool weAre) {
        return true;
    }

    function transfer(address _to, uint256 _value) public {
        require (_to != 0x0);                                           // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[msg.sender] >= _value);                      // Check if the sender has enough
        require (balanceOf[_to] + _value >= balanceOf[_to]);            // Check for overflows
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value); // Subtract from the sender
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);               // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                              // Notify anyone listening that this transfer took place
    }

    function transferFrom(address _from, address _to, uint256 _value) public {
        require (_to != 0x0);                                           // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);                           // Check if the sender has enough
        require (balanceOf[_to] + _value >= balanceOf[_to]);            // Check for overflows
        require (_value <= allowance[_from][msg.sender]);               // Check allowance
        balanceOf[_from] = safeSub(balanceOf[_from], _value);           // Subtract from the sender
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);               // Add the same to the recipient

        uint256 _allowance = allowance[_from][msg.sender];
        allowance[_from][msg.sender] = safeSub(_allowance, _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function totalSupply() public constant returns (uint256 totalSupply) {
        return totalSupply;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    /* Allow another contract to spend some tokens on your behalf.
     * To change the approve amount you first have to reduce the addresses allowance to zero by calling
     * approve(_spender, 0) if it is not already 0 to mitigate the race condition described here:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729 */
    function approve(address _spender, uint _value) public {
        require ((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public constant returns (uint remaining) {
        return allowance[_owner][_spender];
    }
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

contract AlsToken is StandardToken, Owned {

    string public constant name = "Alicoin";
    string public constant symbol = "ALS";
    uint8 public constant decimals = 18;        // Same as ETH

    address public preIcoAddress;
    address public icoAddress;

    // pre-ICO end time in seconds since epoch.
    // Equivalent to Monday, September 25, 2017 00:00:00 UTC
    uint256 public constant preIcoEndTime = 1506297600;

    // ICO end time in seconds since epoch.
    // Equivalent to Monday, October 30, 2017 00:00:00 UTC
    uint256 public constant icoEndTime = 1509321600;

    // 1 million ALS with 18 decimals [10 to the power of (6 + 18) tokens].
    uint256 private oneMillionAls = 10 ** (6 + decimals);

    bool private preIcoTokensWereBurned = false;
    bool private icoTokensWereBurned = false;
    bool private teamTokensWereAllocated = false;

    /* Initializes the initial supply of ALS to 80 million.
     * For more details about the token's supply and allocation see [ToDo: Link] */
    function AlsToken() {
        totalSupply = 80 * oneMillionAls;
    }

    modifier onlyAfterPreIco() {
        require(now >= preIcoEndTime);
        _;
    }

    modifier onlyAfterIco() {
        require(now >= icoEndTime);
        _;
    }

    /* Sets the pre-ICO address and allocates it 10 million tokens.
     * Can be invoked only by the owner.
     * Can be called only once. Once set, the pre-ICO address can not be changed. Any subsequent calls to this method will be ignored. */
    function setPreIcoAddress(address _preIcoAddress) external onlyOwner {
        require (preIcoAddress == address(0x0));

        preIcoAddress = _preIcoAddress;
        balanceOf[preIcoAddress] = 10 * oneMillionAls;

        PreIcoAddressSet(preIcoAddress);
    }

    /* Sets the ICO address and allocates it 70 million tokens.
     * Can be invoked only by the owner.
     * Can be called only once. Once set, the ICO address can not be changed. Any subsequent calls to this method will be ignored. */
    function setIcoAddress(address _icoAddress) external onlyOwner {
        require (icoAddress == address(0x0));

        icoAddress = _icoAddress;
        balanceOf[icoAddress] = 70 * oneMillionAls;

        IcoAddressSet(icoAddress);
    }

    // Burns the tokens not sold during the pre-ICO. Can be invoked only after the pre-ICO ends.
    function burnPreIcoTokens() external onlyAfterPreIco {
        require (!preIcoTokensWereBurned);

        uint256 tokensToBurn = balanceOf[preIcoAddress];
        if (tokensToBurn > 0)
        {
            balanceOf[preIcoAddress] = 0;
            totalSupply = safeSub(totalSupply, _value);
        }

        preIcoTokensWereBurned = true;
        Burned(preIcoAddress, tokensToBurn);
    }

    // Burns the tokens not sold during the ICO. Can be invoked only after the ICO ends.
    function burnIcoTokens() external onlyAfterIco {
        require (!icoTokensWereBurned);

        uint256 tokensToBurn = balanceOf[icoAddress];
        if (tokensToBurn > 0)
        {
            balanceOf[icoAddress] = 0;
            totalSupply = safeSub(totalSupply, _value);
        }

        icoTokensWereBurned = true;
        Burned(icoAddress, tokensToBurn);
    }


    function allocateTeamAndPartnerTokens(address _teamAddress, address _partnersAddress) external onlyOwner {
        require (preIcoTokensWereBurned);
        require (icoTokensWereBurned);
        require (!teamTokensWereAllocated);

        uint256 oneTenth = safeDiv(totalSupply, 8);

        balanceOf[_teamAddress] = oneTenth;
        totalSupply = safeAdd(totalSupply, oneTenth);

        balanceOf[_partnersAddress] = oneTenth;
        totalSupply = safeAdd(totalSupply, oneTenth);

        teamTokensWereAllocated = true;

        TeamAndPartnerTokensAllocated(_teamAddress, _partnersAddress);
    }

    // Event triggered when the Pre-ICO address was set.
    event PreIcoAddressSet(address _preIcoAddress);

    // Event triggered when the ICO address was set.
    event IcoAddressSet(address _icoAddress);

    // Event triggered when pre-ICO or ICO tokens were burned.
    event Burned(address _address, uint256 _amount);

    // Event triggered when team and partner tokens were allocated.
    event TeamAndPartnerTokensAllocated(address _teamAddress, address _partnersAddress);
}
