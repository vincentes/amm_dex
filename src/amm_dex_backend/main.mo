import Result "mo:base/Result";
import Nat "mo:base/Nat";
import Float "mo:base/Float";
import Int "mo:base/Int";

// NOTE: For the purpose of this challenge, this implementation focuses on core AMM functionality without 
// token ledger integration. A production AMM would typically integrate with:
// - TokenA Ledger Canister (for tokenA balance/transfer management)
// - TokenB Ledger Canister (for tokenB balance/transfer management) 
// - LP Token Ledger Canister (for tracking liquidity provider token ownership)
// The current implementation only tracks pool state and overall LP token supply, assuming token transfers 
// and LP token accounting are handled externally.
actor AmmDex {
  private stable var tokenAReserve : Nat = 0;
  private stable var tokenBReserve : Nat = 0;
  private stable var totalLPTokens : Nat = 0;
  private let MINIMUM_LIQUIDITY : Nat = 1000;
  private let FEE_NUMERATOR : Nat = 3;
  private let FEE_DENOMINATOR : Nat = 1000;

  type LiquidityResult = Result.Result<Bool, Text>;
  type RemoveLiquidityResult = Result.Result<(Nat, Nat), Text>;
  type TokenType = { #TokenA; #TokenB };
  type SwapResult = Result.Result<Nat, Text>;

  private func getSwapAmount(amountIn : Nat, reserveIn : Nat, reserveOut : Nat) : Nat {
    let amountInWithFee = amountIn * (FEE_DENOMINATOR - FEE_NUMERATOR);
    let numerator = amountInWithFee * reserveOut;
    let denominator = (reserveIn * FEE_DENOMINATOR) + amountInWithFee;
    return numerator / denominator;
  };

  private func calculateLPTokens(amountA : Nat, amountB : Nat) : Nat {
    if (totalLPTokens == 0) {
      return Nat.max(Int.abs(Float.toInt(Float.sqrt(Float.fromInt(amountA * amountB)))), MINIMUM_LIQUIDITY);
    };

    let lpTokenA = (amountA * totalLPTokens) / tokenAReserve;
    let lpTokenB = (amountB * totalLPTokens) / tokenBReserve;
    return Nat.min(lpTokenA, lpTokenB);
  };

  public shared func addLiquidity(tokenA : Nat, tokenB : Nat) : async LiquidityResult {
    if (tokenA == 0 or tokenB == 0) {
      return #err("Invalid input amounts");
    };

    if (tokenAReserve == 0 and tokenBReserve == 0) {
      tokenAReserve := tokenA;
      tokenBReserve := tokenB;
      totalLPTokens := calculateLPTokens(tokenA, tokenB);
      return #ok(true);
    };

    let expectedTokenB = (tokenA * tokenBReserve) / tokenAReserve;
    if (tokenB > expectedTokenB) {
      if (Int.abs(tokenB - expectedTokenB) > expectedTokenB / 100) {
        return #err("Unbalanced liquidity provision");
      };
    } else {
      if (Int.abs(expectedTokenB - tokenB) > expectedTokenB / 100) {
        return #err("Unbalanced liquidity provision");
      };
    };

    tokenAReserve += tokenA;
    tokenBReserve += tokenB;
    totalLPTokens += calculateLPTokens(tokenA, tokenB);
    return #ok(true);
  };

  public shared func removeLiquidity(lpTokens : Nat) : async RemoveLiquidityResult {
    if (lpTokens == 0 or lpTokens > totalLPTokens) {
      return #err("Invalid LP token amount");
    };

    let tokenAAmount = (lpTokens * tokenAReserve) / totalLPTokens;
    let tokenBAmount = (lpTokens * tokenBReserve) / totalLPTokens;

    if (tokenAAmount == 0 or tokenBAmount == 0) {
      return #err("Insufficient liquidity to remove");
    };

    tokenAReserve -= tokenAAmount;
    tokenBReserve -= tokenBAmount;
    totalLPTokens -= lpTokens;

    return #ok((tokenAAmount, tokenBAmount));
  };

  public shared func swap(tokenIn : TokenType, amountIn : Nat) : async SwapResult {
    if (amountIn == 0) {
      return #err("Invalid input amount");
    };

    switch (tokenIn) {
      case (#TokenA) {
        if (tokenAReserve == 0 or tokenBReserve == 0) {
          return #err("Insufficient liquidity");
        };
        let amountOut = getSwapAmount(amountIn, tokenAReserve, tokenBReserve);
        if (amountOut == 0 or amountOut >= tokenBReserve) {
          return #err("Insufficient liquidity for swap");
        };
        tokenAReserve += amountIn;
        tokenBReserve -= amountOut;
        return #ok(amountOut);
      };
      case (#TokenB) {
        if (tokenAReserve == 0 or tokenBReserve == 0) {
          return #err("Insufficient liquidity");
        };
        let amountOut = getSwapAmount(amountIn, tokenBReserve, tokenAReserve);
        if (amountOut == 0 or amountOut >= tokenAReserve) {
          return #err("Insufficient liquidity for swap");
        };
        tokenBReserve += amountIn;
        tokenAReserve -= amountOut;
        return #ok(amountOut);
      };
    };
  };

  public query func getPoolState() : async (Nat, Nat, Nat) {
    return (tokenAReserve, tokenBReserve, totalLPTokens);
  };

  public query func greet(name : Text) : async Text {
    return "Hello, " # name # "!";
  };
};
