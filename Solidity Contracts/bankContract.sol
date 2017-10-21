pragma solidity ^0.4.17;

/**
 * @title Ouroboros Contract
 * @author AL_X
 * @dev The Ouroboros interface
 */
contract Ouroboros {
    function getFee() public view returns (uint256) {}
    
    function isOuroborosCompatible(address _toCheck) public view returns(bool) {}
    
    function updateInterbankLedger(address _senderBank, address _recipientBank, uint256 _value) public {}
}

/**
 * @title Sample Bank Contract
 * @author AL_X
 * @dev The SBC Cryptocurrency Contract showcasing how Ethereum smart contracts can be used as public ledgers
 */
contract SampleBankContract {
    string public name = "Sample Bank";
    string public symbol = "SBC";
    address public APIaddress;
    mapping(address => uint256) balances;
    
    mapping(address => bool) isATM;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
	/**
	 * @notice Ensures the API address is the caller
	 */
    modifier isAPI() {
        require(msg.sender == APIaddress);
        //Continue executing rest of method body
        _;
    }
    
    /**
     * @notice Ensures an ATM address is the caller
     */
    modifier ATMonly() {
        require(isATM[msg.sender]);
        _;
    }
    
    /**
	 * @notice SafeMath Library safeSub Import
	 * @dev 
			The solidity language has certain limitations 
			because it only deals with unsigned integers.
			This means that both underflows & overflows 
			can occur but only underflows concern our contract
			since a bank's currency will never realistically
			surpass the capacity of a 256-bit unsigned 
			integer (2^256-1).
	 */
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256 z) {
        assert((z = a - b) <= a);
    }
	/**
	 * @notice SBC Constructor
	 * @dev 
			Constructor function assigning API rights to the address
			that created the contract as well as assigning the first 
			ATMs.
	 */
    function SampleBankContract(address[] ATMs) public {
        APIaddress = msg.sender;
        for (uint16 i = 0; i < ATMs.length; i++) {
            isATM[ATMs[i]] = true;
        }
    }
    
    /**
     * @notice Query the available balance of an address. We only want the bank's API or the bank's ATM to check a specific addresses' balance
	 * @param _owner The address whose balance we wish to retrieve
     * @return balance Balance of the address
     */
    function balanceOf(address _owner) external view returns (uint256 balance) {
        require(APIaddress == msg.sender || isATM[msg.sender]);
        return balances[_owner];
    }
    
    /**
     * @notice Query the available balance of the caller. This is used for building interface such as the one Ouroboros offers. Allows only you to see your balance.
     * @return balance Balance of the caller
     */
    function balanceOf() external view returns (uint256 balance) {
        return balances[msg.sender];
    }
    
    /**
	 * @notice Transfer the specified Euro amount to the target address
	 * @param _to The address you wish to send the money to
	 * @param _value The amount of money you wish to send
	 * @return success Transaction success. Called by programs to ensure a transaction is successful before broadcasting it to the network
     */
    function transfer(address _to, uint256 _value) external returns (bool success) {
        if (isContract(_to)) {
            return transferToBankOrContract(_to, _value);
        } else {
            return transferToAddress(_to, _value);
        }
    }
    
    /**
	 * @notice Check whether address is a contract (Code associated with address on the network). Used for interacting with smart contracts.
	 * @param _address The address to check
	 * @return is_contract Result of query
     */
    function isContract(address _address) internal view returns (bool is_contract) {
        uint length;
        assembly {
            length := extcodesize(_address)
        }
        return length > 0;
    }
    
    /**
	 * @notice Handles transfer to an ECA (Externally Controlled Account), a normal account
	 * @param _to The address to transfer to
	 * @param _value The amount of Euros to transfer multiplied by 100 since there are no decimals in Solidity
	 * @return success Transaction success
     */
    function transferToAddress(address _to, uint256 _value) internal returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = balances[_to]+_value;
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    /**
	 * @notice Handles transfer to a contract or bank
	 * @param _to The address to transfer to
	 * @param _value The amount of money to transfer
	 * @return success Transaction success
     */
    function transferToBankOrContract(address _to, uint256 _value) internal returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = balances[_to]+_value;
        SampleBankContract bank = SampleBankContract(_to);
        bank.contractInteraction(msg.sender, _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    /**
	 * @notice Adds an ATM to the list of verified ATMs
	 * @param _to The address to assign ATM rights to
     */
    function enableATM(address _newATM) external {
        isATM[_newATM] = true;
    }
    
    /**
	 * @notice Removes an ATM to the list of verified ATMs
	 * @param _to The address to remove ATM rights from
     */
    function disableATM(address _ATM) external {
        isATM[_ATM] = false;
    }
	
	/**
	* @notice Sample interaction between banks. 
	* @dev    
	*         If another bank sends money to this bank, the money is credited 
	*         as if the money was given by SampleBankContract.
	*         Interbank "loans" are tracked by a public (to banks) Ouroboros array.
	*         There are more interactions that can be done (Check which bank sent the money et. al.) 
	*         but for the purposes of this competition we are sticking to simple interactions.
	* 
	* @param _sender The user who sent the money
	* @param _value The amount of Euros the address sent to this contract
	*/
	function contractInteraction(address _sender, uint256 _value) public {
		Ouroboros instance = Ouroboros(0x0);
		_value = (_value * instance.getFee())/100;
		balances[_sender] += _value;
		require(instance.isOuroborosCompatible(msg.sender));
		instance.updateInterbankLedger(msg.sender, this, _value);
	}
}