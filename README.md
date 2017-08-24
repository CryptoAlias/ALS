# ALS

<br />

## Table Of Contents

* [Intro](#intro)
* [ALS distribution](#als-distribution)
* [Token contract](#token-contract)
* [Pre-ICO contract](#pre-ico-contract)
* [ICO contract](#ico-contract)

<br />

## Intro
This repository contains the solidity source code for the ALS token, pre-ICO, and ICO contracts.

ALS is an ERC20 token and the native currency on the [CryptoAlias](https://cryptoalias.io) DAPP, that can be used to acquire aliases for blockchain addresses.
For more information about [CryptoAlias](https://cryptoalias.io) please visit the [website](https://cryptoalias.io).

To offer some context, this document begins by describing the ALS token distribution. Consequently, an analysis of the token, pre-ICO, and ICO contracts is presented.

## ALS distribution

| Token allocation | Percentage     | Count           |
| ---------------- | :------------: | :-------------: |
| Pre-ICO          | ~ 10%          | max 10.000.000  |
| ICO              | ~ 70%          | max 70.000.000  |
| Team             | 10%            | (Pre-ICO + ICO) / 8   |
| Partnerships     | 10%            | (Pre-ICO + ICO) / 8   |
| **_Total_**      | **_100%_**     | **_max 100.000.000_** |

As illustrated in the table above, the maximum number of ALS tokens is 100 million.

80 million tokens were issued upon token creation. 10 million of them were allocated for the pre-ICO, and the other 70 million were allocated for the ICO. The CryptoAlias team has no control over these tokens, as they are being managed by the pre-ICO and ICO contracts.
Any tokens not sold during the pre-ICO and the ICO will be burned, and the shares of the token holders will increase proportionally.

After the ICO completes and the unsold tokens are burnt, the token contract will issue the team tokens and the partnership tokens. Both the team and partnership tokens will represent 10% of the total final amount of tokens (equivalent to 1/8 of the total tokens sold).
After the team and partnership tokens are issued, no more ALS tokens can ever be created or burnt.

To illustrate the process described above, here are 2 use cases:
- If all tokens are sold during the pre-ICO and the ICO, then 10 million tokens will be issued for the team and 10 million tokens will be issued for partners. The total final amount of ALS tokens will be 100 million.

- If 5 million tokens are sold during the pre-ICO and 59 million tokens are sold during the ICO, then 8 million tokens will be issued for the team and 8 million tokens will be issued for partners. The total final amount of tokens will be 80 million.

## Token contract

AlsToken is an ERC20 token and thus extends the ERC20 contract (see https://github.com/ethereum/EIPs/issues/20). Notice that in order to change the approve amount, the caller must first reduce the address's allowance to zero by calling ```approve(_spender, 0)``` if it is not zero already. This allows to mitigate the race condition described [here](https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729).

To ensure that all mathematical computations are valid and executed as expected, AlsToken extends SafeMath and uses its methods for all math operations.

AlsToken also extends the Owned contract, which allows certain functions to be invoked only by the owner (the CryptoAlias team).

The token name, symbol, and decimals are hardcoded into the code, as well as the end time of the pre-ICO and ICO. These values can not be changed.

Upon creation, the ALS supply is set to 80 million tokens, however no tokens are allocated yet to any address. The tokens will be automatically allocated to the pre-ICO address (10 million tokens) and ICO address (70 million tokens) once these addresses are set up by the admin.
The reason why the addresses are not set up upon token creation is that the crowdsale contracts need to reference the token contract, while the token contract needs to reference the crowdsale contracts (the Chicken-and-egg problem). As a result, in order to solve this problem, the token contract is created first without referencing the crowdsale addresses. After the crowdsales are created, the pre-ICO and ICO addresses can be set up only by the owner using the ```setPreIcoAddress(address _preIcoAddress)``` and ```setIcoAddress(address _icoAddress)``` functions. To ensure total transparency, these functions can be invoked only once. So after the addresses are set, they can not be changed. The CryptoAlias team undertakes the responsibility to set the pre-ICO and ICO addresses within a day of the token creation, and long before the start of the pre-ICO.

The ```burnPreIcoTokens()``` function burns all the tokens that were allocated for the pre-ICO but were not bought. It can be called only after the pre-ICO ends. The function can be invoked by anyone and can be executed only once. If the tokens weren't sold out, this function will decrease the ALS total supply.
Analogously, the ```burnIcoTokens()``` function allows to burn the tokens not sold during the ICO. 

The ```allocateTeamAndPartnerTokens(address _teamAddress, address _partnersAddress)``` function allocates the team and partner tokens. It can be invoked only by the owner, only after the ICO ends, and only if the unsold tokens were burned. Obviously, after the team and partner tokens are generated, the function can not be invoked again. This function will increase the total ALS supply by 20%. After its execution, no more ALS tokens can ever be created or burned.


## Pre-ICO contract
The pre-ICO contract extends the SafeMath and Owned contracts, similarly to the AlsToken contract and for the same reasons.

The crowdsale start time, end time, and token price are hardcoded into the contract's code. During the pre-ICO, the token price is constant: 2000 ALS per 1 ETH.

Upon contract creation, the ALC token address is set and can not be changed.

The contract will accept payments during the pre-ICO period, as long as the tokens allocated for the crowdsale are not sold out. Any payments sent before or after the pre-ICO will be rejected. Payments sent after the tokens were sold out will be rejected as well.

If during a buy there are ALS tokens available for sale, but amount of existing tokens is less than the amount requested, then the contract will sell the existing tokens, keep the equivalent of their price from the received ETH, and return the rest of the ETH back to the caller.

## ICO contract
The ICO contract is identical to the pre-ICO contract with the exception of the crowdsale start time, end time, and token price.

In contrast to the pre-ICO, the token price during the ICO is varying depending on time. The earlier buyers invest, the more tokens they receive. The dependency of the ALS token price on time is illustrated in the table below:

| Time since ICO start | Exchange rate     |
| :------------------: | :---------------: |
| < 1 day              | 1 ETH = 1250 ALS  |
| < 3 days             | 1 ETH = 1200 ALS  |
| < 6 days             | 1 ETH = 1150 ALS  |
| < 10 days            | 1 ETH = 1100 ALS  |
| < 15 days            | 1 ETH = 1050 ALS  |
| > 15 days            | 1 ETH = 1000 ALS  |

The ICO crowdsale will end after 21 days from its start, or when all the allocated tokens are sold out.
