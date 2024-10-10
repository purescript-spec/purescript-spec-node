module Test.Spec.Runner.Node where

import Prelude

import Data.Identity (Identity(..))
import Data.Newtype (un)
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Aff.Class (class MonadAff)
import Effect.Class (class MonadEffect, liftEffect)
import Node.Process (exit')
import Test.Spec (Spec, SpecT)
import Test.Spec.Result (Result)
import Test.Spec.Runner (Reporter)
import Test.Spec.Runner as Spec
import Test.Spec.Runner.Node.Config as Cfg
import Test.Spec.Runner.Node.Persist as Persist
import Test.Spec.Summary (successful)
import Test.Spec.Tree (Tree)

type Args c =
  { defaultConfig :: Cfg.TestRunConfig' c
  , parseCLIOptions :: Boolean
  }

defaultArgs :: Args ()
defaultArgs = { defaultConfig: Cfg.defaultConfig, parseCLIOptions: true }

argsToConfig ::
  forall c m
  .  MonadEffect m
  => Args c
  -> m (Cfg.TestRunConfig' c)
argsToConfig args =
  if args.parseCLIOptions then
    Cfg.fromCommandLine' args.defaultConfig Cfg.commandLineOptionParsers
  else
    pure args.defaultConfig

-- | Runs the given spec, using configuration derived from CLI options (if any),
-- | and exits the process with an exit indicating success or failure.
runSpecAndExitProcess :: Array Reporter -> Spec Unit -> Effect Unit
runSpecAndExitProcess = runSpecAndExitProcess' defaultArgs

-- | Runs the given spec and exits the process with an exit code indicating
-- | success or failure.
-- |
-- | The `parseCLIOptions` parameter determines whether the `defaultConfig`
-- | should be used as is or CLI options (if any provided) should be applied on
-- | top of it.
runSpecAndExitProcess' :: ∀ c.
  Args c
  -> Array Reporter
  -> Spec Unit
  -> Effect Unit
runSpecAndExitProcess' args reporters spec = launchAff_ do
  m <- runSpecAndExitProcessM args reporters spec
  un Identity $ m

runSpecAndExitProcessM ::
  ∀ c m mAff
  . Functor m
  => MonadAff mAff
  => Args c
  -> Array Reporter
  -> SpecT Aff Unit m Unit
  -> mAff (m (Aff Unit))
runSpecAndExitProcessM args reporters spec = do
  config <- argsToConfig args
  (res :: m (Aff (Array (Tree String Void Result)))) <- runSpecAndGetResultsM config reporters spec
  let (results' :: m (Aff Unit)) =
        res <#> \affArray -> do
          results <- affArray
          liftEffect $ exit' $ if successful results then 0 else 1
  pure $ results'

runSpecAndGetResultsM ::
  ∀ c m mAff
  . Functor m
  => MonadAff mAff
  => Cfg.TestRunConfig' c
  -> Array Reporter
  -> SpecT Aff Unit m Unit
  -> mAff (m (Aff (Array (Tree String Void Result))))
runSpecAndGetResultsM config reporters spec = do
  specCfg <- Cfg.toSpecConfig config <#> _ { exit = false }
  let (results :: m (Aff (Array (Tree String Void Result)))) = Spec.evalSpecT specCfg reporters spec
  let (results' :: m (Aff (Array (Tree String Void Result)))) =
        results <#> \affArray -> do
          results <- affArray
          Persist.persistResults results
          pure results
  pure results'
