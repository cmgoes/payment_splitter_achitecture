
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Token Payment Splitter of protocol
 * @notice It splits Treasury token to Owner EOA/VCs/Stakers treasury contracts based on shares.
 */

contract TokenPaymentSplitter is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  event PayeeAdded(address account, uint256 shares);
  event PaymentReleased(address to, uint256 amount);

  address internal paymentToken; //address of erc20 token
  uint256 internal _totalShares; //total shares from all payees
  uint256 internal _totalTokenReleased; //total amount released to all payees
  address[] internal _payees; //address of payees
  mapping(address => uint256) internal _shares; //shares per address payee
  mapping(address => uint256) internal _tokenReleased; //amount of token per payee's address

  /**
    * @notice Constructor
    * @param _payees array of payee's address
    * @param _shares array of amount per payee's address
    * @param _paymentToken usdt token address  
  */
  constructor(
    address[] memory payees,
    uint256[] memory shares,
    address _paymentToken
  ) {
    require(
        payees.length == shares.length,
        "Payees and shares length mismatch"
    );
    require(payees.length > 0, "No payees");
    for (uint256 i = 0; i < payees.length; i++) {
        _addPayee(payees[i], shares[i]);
    }
    paymentToken = IERC20(_paymentToken);
  }

  function totalShares() public view returns (uint256) {
    return _totalShares;
  }

  function shares(address account) public view returns (uint256) {
    return _shares[account];
  }

  function payee(uint256 index) public view returns (address) {
    return _payees[index];
  }

  function release(address account) public virtual {
    require(
        _shares[account] > 0,
        "account has no shares"
    );

    uint256 tokenTotalReceived = IERC20(paymentToken).balanceOf(
        address(this)
    ) + _totalTokenReleased;
    uint256 payment = (tokenTotalReceived * _shares[account]) /
        _totalShares -
        _tokenReleased[account];

    require(
        payment != 0,
        "account is not due payment"
    );

    _tokenReleased[account] = _tokenReleased[account] + payment;
    _totalTokenReleased = _totalTokenReleased + payment;

    IERC20(paymentToken).safeTransfer(account, payment);
    emit PaymentReleased(account, payment);
  }

  function PendingRewards(address account) public view returns (uint256) {
    if (_shares[account] == 0) {
        return 0;
    }

    uint256 tokenTotalReceived = IERC20(paymentToken).balanceOf(address(this)) + _totalTokenReleased;
    uint256 payment = ((tokenTotalReceived * _shares[account]) / _totalShares) -
        _tokenReleased[account];

    return payment;
  }


  function _addPayee(address account, uint256 shares_) internal {
    require(
        account != address(0),
        "account is the zero address"
    );
    require(shares_ > 0, "shares are 0");
    require(
        _shares[account] == 0,
        "account already has shares"
    );
    _payees.push(account);
    _shares[account] = shares_;
    _totalShares = _totalShares + shares_;
    emit PayeeAdded(account, shares_);
  }
}