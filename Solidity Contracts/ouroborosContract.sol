pragma solidity ^0.4.17;

/**
 * @title Ouroboros Contract
 * @author AL_X
 * @dev The Ouroboros contract handling the interbank transactions
 */
contract Ouroboros {
    uint256 private ouroborosFee;
    uint256 private purposedFee;
    
    address[] private bankAddresses;
    
    uint16 private feeVotes;
    uint16 private entryVotes;
    
    address private purposedBank;
    
    mapping(address => bool) feeVoting;
    mapping(address => bool) bankEntryVoting;
    mapping(address => bool) ouroborosCompatibleBanks;
    
    mapping(address => mapping(address => uint256)) ouroborosLedger;
    
    event purposedFeeResult(bool result);
    event purposedBankResult(bool result);
    
	/**
	 * @notice Ensures Ouroboros authorized banks are the callers
	 */
    modifier bankOnly() {
        require(ouroborosCompatibleBanks[msg.sender]);
        _;
    }
	
	/**
	 * @notice The Ouroboros constructor requiring at least 2 banks to comply with the protocol
	 */
	function Ouroboros(address secondBank) public {
		ouroborosCompatibleBanks[msg.sender] = true;
		ouroborosCompatibleBanks[secondBank] = true;
		bankAddresses.push(msg.sender);
		bankAddresses.push(secondBank);
	}
    
	/**
     * @notice Query the current agreed upon transaction fee
     * @return _fee The current Ouroboros fee in percentage
     */
    function getFee() public view returns (uint256 _fee) {
        return ouroborosFee;
    }
    
	/**
     * @notice Check whether the supplied address is an Ouroboros compatible bank
	 * @param _toCheck The address to check
     * @return isCompatible Whether or not the address is compatible 
     */
    function isOuroborosCompatible(address _toCheck) public view returns(bool isCompatible) {
        return ouroborosCompatibleBanks[_toCheck];
    }
    
	/**
	 * @notice Log the specified Euro transaction on the Ouroboros Ledger
	 * @param _senderBank The bank that owes money
	 * @param _recipientBank The bank that credited the transaction
	 * @param _value The amount of money transfered
	 */
    function updateInterbankLedger(address _senderBank, address _recipientBank, uint256 _value) public bankOnly {
        if (ouroborosLedger[_recipientBank][_senderBank] > 0) {
            if (ouroborosLedger[_recipientBank][_senderBank] < _value) {
                ouroborosLedger[_senderBank][_recipientBank] = _value - ouroborosLedger[_recipientBank][_senderBank];
                ouroborosLedger[_recipientBank][_senderBank] = 0;
            } else {
                ouroborosLedger[_recipientBank][_senderBank] -= _value;
            }
        } else {
            ouroborosLedger[_senderBank][_recipientBank] += _value;
        }
    }
    
	/**
	 * @notice Purpose a new fee to the Ouroboros Network
	 * @param _newFee The new fee percentage
	 */
    function purposeNewFee(uint256 _newFee) public bankOnly {
        require(purposedFee == 0);
        for (uint16 i = 0; i < bankAddresses.length; i++) {
            feeVoting[bankAddresses[i]] = false;
        }
        purposedFee = _newFee;
    }
    
	/**
	 * @notice Accept the currently purposed fee
	 */
    function acceptNewFee() public bankOnly {
        require(purposedFee > 0 && !feeVoting[msg.sender]);
        feeVoting[msg.sender] = true;
        feeVotes++;
        if (feeVotes == bankAddresses.length) {
            ouroborosFee = purposedFee;
            purposedFee = 0;
            feeVotes = 0;
            purposedFeeResult(true);
        }
    }
    
	/**
	 * @notice Decline the currently purposed fee
	 */
    function declineNewFee() public bankOnly {
        purposedFee = 0;
        feeVotes = 0;
        purposedFeeResult(false);
    }
    
	/**
	 * @notice Purpose a new bank to the Ouroboros Network
	 * @param newBank The new bank's address
	 */
    function purposeNewBank(address newBank) public bankOnly {
        require(purposedBank == 0x0);
        for (uint16 i = 0; i < bankAddresses.length; i++) {
            bankEntryVoting[bankAddresses[i]] = false;
        }
        purposedBank = newBank;
    }
    
	/**
	 * @notice Accept the currently purposed bank
	 */
    function acceptNewBank() public bankOnly {
        require(purposedBank != 0x0 && !bankEntryVoting[msg.sender]);
        bankEntryVoting[msg.sender] = true;
        entryVotes++;
        if (entryVotes == bankAddresses.length) {
            ouroborosCompatibleBanks[purposedBank] = true;
            bankAddresses.push(purposedBank);
            purposedBank = 0x0;
            entryVotes = 0;
            purposedBankResult(true);
        }
    }
    
	/**
	 * @notice Accept the currently purposed bank
	 */
    function declineNewBank() public bankOnly {
        purposedBank = 0x0;
        entryVotes = 0;
        purposedBankResult(false);
    }
	
	/**
	 * @dev Similarly, other voting systems such as contract acception etc. can be implemented as required.
	 */
    
	/**
     * @notice Check the Ouroboros ledger
	 * @param _bank1 The first bank
	 * @param _bank2 The second bank
     * @return amount The amount owed
     * @return polarity Whether it is positive or not
     */
    function checkLedger(address _bank1, address _bank2) public view returns (uint256 amount, bool polarity) {
        if (ouroborosLedger[_bank1][_bank2] > 0) {
            return (ouroborosLedger[_bank1][_bank2],true);
        } else {
            return (ouroborosLedger[_bank2][_bank1],false);
        }
    }
}