pragma solidity ^0.5.8;


/**
 * This Basket contract is essentially just a data structure; it represents the tokens and weights
 * in some Reserve-backing basket, either proposed or accepted.
 *
 * Each `weights` value has the unit aqToken/RSV. That is, atto-quantum-Tokens per
 * RSV. (Alternately, you can think about this as if the weights value is itself an 18-decimal
 * fixed-point value with unit qToken/RSV. It'd certainly be prettier if these we just
 * straightforwardly qTokens/RSV, but that introduces unacceptable rounding error in some of our
 * basket computations.)
 *
 * For example, let's say we have the token USDX in the vault, and it's represented to 6 decimal
 * places, and the RSV basket should include 3/10ths of a USDX for each RSV. Then the corresponding
 * basket weight will be represented as 3*(10**23), because:
 *
 * 3*(10**23) aqToken/RSV == 0.3 Token/RSV * (10**6 qToken/Token) * (10**18 aqToken/qToken)
*/

contract Basket {
    address[] public tokens;
    mapping(address => uint256) public weights; // unit: aqToken/RSV
    mapping(address => bool) public has;
    // INVARIANT: {addr | addr in tokens} == {addr | has[addr] == true}

    // SECURITY PROPERTY: The value of prev is always a Basket, and cannot be set by any user.
    // SECURITY PROPERTY: A basket can be of size 0. It is the Manager's responsibility
    //                    to ensure Issuance does not happen against an empty basket.
    constructor(Basket prev, address[] memory _tokens, uint256[] memory _weights) public {
        require(_tokens.length == _weights.length, "Basket: unequal array lengths");
        require(_tokens.length <= 100, "Basket: bad length");

        // Initialize data from input arrays
        tokens = new address[](_tokens.length);
        for (uint i = 0; i < _tokens.length; i++) {
            weights[_tokens[i]] = _weights[i];
            has[_tokens[i]] = true;
            tokens[i] = _tokens[i];
        }

        // If there's a previous basket, copy those of its contents not already set.
        if (prev != Basket(0)) {
            for (uint i = 0; i < prev.size(); i++) {
                address tok = prev.tokens(i);
                if (!has[tok]) {
                    weights[tok] = prev.weights(tok);
                    has[tok] = true;
                    tokens.push(tok);
                }
            }
        }
    }

    function getTokens() external view returns(address[] memory) {
        return tokens;
    }

    function size() external view returns(uint) {
        return tokens.length;
    }
}
