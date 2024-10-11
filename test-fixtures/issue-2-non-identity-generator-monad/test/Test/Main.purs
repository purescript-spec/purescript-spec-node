module Test.Main where

import Prelude

import Data.Array ((..))
import Data.Array as Array
import Data.Foldable (for_)
import Data.Int as Int
import Data.Maybe (fromMaybe)
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Class (liftEffect)
import Node.Process (argv)
import Test.Spec (SpecT)
import Test.Spec as Spec
import Test.Spec.Assertions (shouldEqual)
import Test.Spec.Reporter (consoleReporter)
import Test.Spec.Runner.Node (runSpecAndExitProcess')
import Test.Spec.Runner.Node.Config (defaultConfig)

main :: Effect Unit
main = runSpecAndExitProcess'
  { defaultConfig, parseCLIOptions: false }
  [consoleReporter]
  spec

spec :: SpecT Aff Unit Effect Unit
spec = do

  arg <- Array.index <$> liftEffect argv <@> 2
  let numTests = arg >>= Int.fromString # fromMaybe 3

  when (numTests >= 1) $
    for_ (1..numTests) \i -> do
      Spec.it ("test number " <> show i) do
        (i + i - i) `shouldEqual` i
