module Tests.Pool where

import qualified ErgoDex.PContracts.PPool as PPool
import qualified ErgoDex.Contracts.Pool   as Pool
import ErgoDex.PValidators

import Eval
import Gen.Utils

import Plutus.V1.Ledger.Api

import Hedgehog

import Test.Tasty
import Test.Tasty.HUnit
import Test.Tasty.Hedgehog as HH

import Gen.Models
import Gen.DepositGen
import Gen.PoolGen
import Gen.SwapGen

checkPool = testGroup "CheckPoolContract"
  [ HH.testProperty "pool_deposit_is_correct" successPoolDeposit
  , HH.testProperty "pool_swap_is_correct" successPoolSwap
  ]

checkPoolRedeemer = testGroup "CheckPoolRedeemer"
  [ HH.testProperty "fail_if_pool_ix_is_incorrect_deposit" poolDepositRedeemerIncorrectIx
  , HH.testProperty "fail_if_pool_action_is_incorrect_deposit_to_redeem" (poolDepositRedeemerIncorrectAction Pool.Redeem)
  , HH.testProperty "fail_if_pool_action_is_incorrect_deposit_to_swap" (poolDepositRedeemerIncorrectAction Pool.Swap)
  , HH.testProperty "fail_if_pool_ix_is_incorrect_swap" poolSwapRedeemerIncorrectIx
  , HH.testProperty "fail_if_pool_action_is_incorrect_swap_to_deposit" (poolSwapRedeemerIncorrectAction Pool.Deposit)
  , HH.testProperty "fail_if_pool_action_is_incorrect_swap_to_redeem" (poolSwapRedeemerIncorrectAction Pool.Redeem)
  ]

successPoolSwap :: Property
successPoolSwap = property $ do
  let (x, y, nft, lq) = genAssetClasses
  pkh             <- forAll genPkh
  orderTxRef      <- forAll genTxOutRef
  let
    (cfgData, dh) = genSConfig x y nft 100 100 100 pkh 10 1
    orderTxIn     = genSTxIn orderTxRef dh x 10 5000000
    orderTxOut    = genSTxOut dh y 10 5000000 pkh
  
  poolTxRef <- forAll genTxOutRef
  let
    (pcfg, pdh) = genPConfig x y nft lq 1000
    poolTxIn    = genPTxIn poolTxRef pdh x 100 y 10000 lq 9223372036854775797 nft 1 5000000
    poolTxOut   = genPTxOut pdh x 11000 y 9000 lq 9223372036854775787 nft 1 3000000
  
  let
    txInfo  = mkTxInfo poolTxIn orderTxIn poolTxOut orderTxOut
    purpose = mkPurpose poolTxRef

    cxtToData        = toData $ mkContext txInfo purpose
    poolRedeemToData = toData $ mkPoolRedeemer 0 Pool.Swap

    result = eraseRight $ evalWithArgs (wrapValidator PPool.poolValidatorT) [pcfg, poolRedeemToData, cxtToData]

  result === Right ()

poolSwapRedeemerIncorrectIx :: Property
poolSwapRedeemerIncorrectIx = property $ do
  let (x, y, nft, lq) = genAssetClasses
  pkh             <- forAll genPkh
  orderTxRef      <- forAll genTxOutRef
  let
    (cfgData, dh) = genSConfig x y nft 100 100 100 pkh 10 1
    orderTxIn     = genSTxIn orderTxRef dh x 10 5000000
    orderTxOut    = genSTxOut dh y 10 5000000 pkh
  
  poolTxRef <- forAll genTxOutRef
  let
    (pcfg, pdh) = genPConfig x y nft lq 1000
    poolTxIn    = genPTxIn poolTxRef pdh x 100 y 10000 lq 9223372036854775797 nft 1 5000000
    poolTxOut   = genPTxOut pdh x 11000 y 9000 lq 9223372036854775787 nft 1 3000000
  
  let
    txInfo  = mkTxInfo poolTxIn orderTxIn poolTxOut orderTxOut
    purpose = mkPurpose poolTxRef

    cxtToData        = toData $ mkContext txInfo purpose
    poolRedeemToData = toData $ mkPoolRedeemer 1 Pool.Swap

    result = eraseBoth $ evalWithArgs (wrapValidator PPool.poolValidatorT) [pcfg, poolRedeemToData, cxtToData]

  result === Left ()

poolSwapRedeemerIncorrectAction :: Pool.PoolAction -> Property
poolSwapRedeemerIncorrectAction action = property $ do
  let (x, y, nft, lq) = genAssetClasses
  pkh             <- forAll genPkh
  orderTxRef      <- forAll genTxOutRef
  let
    (cfgData, dh) = genSConfig x y nft 100 100 100 pkh 10 1
    orderTxIn     = genSTxIn orderTxRef dh x 10 5000000
    orderTxOut    = genSTxOut dh y 10 5000000 pkh
  
  poolTxRef <- forAll genTxOutRef
  let
    (pcfg, pdh) = genPConfig x y nft lq 1000
    poolTxIn    = genPTxIn poolTxRef pdh x 100 y 10000 lq 9223372036854775797 nft 1 5000000
    poolTxOut   = genPTxOut pdh x 11000 y 9000 lq 9223372036854775787 nft 1 3000000
  
  let
    txInfo  = mkTxInfo poolTxIn orderTxIn poolTxOut orderTxOut
    purpose = mkPurpose poolTxRef

    cxtToData        = toData $ mkContext txInfo purpose
    poolRedeemToData = toData $ mkPoolRedeemer 0 action

    result = eraseBoth $ evalWithArgs (wrapValidator PPool.poolValidatorT) [pcfg, poolRedeemToData, cxtToData]

  result === Left ()

successPoolDeposit :: Property
successPoolDeposit = property $ do
  let (x, y, nft, lq) = genAssetClasses
  pkh             <- forAll genPkh
  orderTxRef      <- forAll genTxOutRef
  let
    (cfgData, dh) = genDConfig x y nft lq 2 pkh 10000
    orderTxIn     = genTxIn orderTxRef dh x 10 y 10 10004
    orderTxOut    = genTxOut dh lq 10 10000 pkh
  
  poolTxRef <- forAll genTxOutRef
  let
    (pcfg, pdh) = genPConfig x y nft lq 1
    poolTxIn    = genPTxIn poolTxRef pdh x 10 y 10 lq 9223372036854775797 nft 1 10000
    poolTxOut   = genPTxOut pdh x 20 y 20 lq 9223372036854775787 nft 1 10000
  
  let
    txInfo  = mkTxInfo poolTxIn orderTxIn poolTxOut orderTxOut
    purpose = mkPurpose poolTxRef

    cxtToData        = toData $ mkContext txInfo purpose
    poolRedeemToData = toData $ mkPoolRedeemer 0 Pool.Deposit

    result = eraseRight $ evalWithArgs (wrapValidator PPool.poolValidatorT) [pcfg, poolRedeemToData, cxtToData]

  result === Right ()

poolDepositRedeemerIncorrectIx :: Property
poolDepositRedeemerIncorrectIx = property $ do
  let (x, y, nft, lq) = genAssetClasses
  pkh             <- forAll genPkh
  orderTxRef      <- forAll genTxOutRef
  let
    (cfgData, dh) = genDConfig x y nft lq 2 pkh 1
    orderTxIn     = genTxIn orderTxRef dh x 10 y 10 1000000
    orderTxOut    = genTxOut dh lq 10 (1000000 - 300) pkh
  
  poolTxRef <- forAll genTxOutRef
  let (pcfg, pdh) = genPConfig x y nft lq 1

  let
    poolTxIn    = genPTxIn poolTxRef pdh x 10 y 10 lq 9223372036854775797 nft 1 1000000
    poolTxOut   = genPTxOut pdh x 20 y 20 lq 9223372036854775787 nft 1 1000000
  
  let
    txInfo  = mkTxInfo poolTxIn orderTxIn poolTxOut orderTxOut
    purpose = mkPurpose poolTxRef

    cxtToData        = toData $ mkContext txInfo purpose
    poolRedeemToData = toData $ mkPoolRedeemer 1 Pool.Deposit

    result = eraseBoth $ evalWithArgs (wrapValidator PPool.poolValidatorT) [pcfg, poolRedeemToData, cxtToData]

  result === Left ()

poolDepositRedeemerIncorrectAction :: Pool.PoolAction -> Property
poolDepositRedeemerIncorrectAction action = property $ do
  let (x, y, nft, lq) = genAssetClasses
  pkh             <- forAll genPkh
  orderTxRef      <- forAll genTxOutRef
  let
    (cfgData, dh) = genDConfig x y nft lq 2 pkh 1
    orderTxIn     = genTxIn orderTxRef dh x 10 y 10 1000000
    orderTxOut    = genTxOut dh lq 10 (1000000 - 300) pkh
  
  poolTxRef <- forAll genTxOutRef
  let (pcfg, pdh) = genPConfig x y nft lq 1

  let
    poolTxIn    = genPTxIn poolTxRef pdh x 10 y 10 lq 9223372036854775797 nft 1 1000000
    poolTxOut   = genPTxOut pdh x 20 y 20 lq 9223372036854775787 nft 1 1000000
  
  let
    txInfo  = mkTxInfo poolTxIn orderTxIn poolTxOut orderTxOut
    purpose = mkPurpose poolTxRef

    cxtToData        = toData $ mkContext txInfo purpose
    poolRedeemToData = toData $ mkPoolRedeemer 0 action

    result = eraseBoth $ evalWithArgs (wrapValidator PPool.poolValidatorT) [pcfg, poolRedeemToData, cxtToData]

  result === Left ()