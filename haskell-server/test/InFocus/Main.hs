--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--


-- | Special hspec main to run only the tests that are currently in focus.
--   See test-suite 'infocus' in .cabal file. Add a 'describe' here for each
--   in-focus test. And add the test module to the infocus test-suite in .cabal.
module Main (
    main
  , spec
  ) where

-- TODO. stack test discovers this as well - and runs it redundantly.
-- TODO. Don't know how to fix. Ignore for now.

import Test.Hspec

import qualified BoardGame.Server.Domain.StripMatcherSpec as TheTest


main :: IO ()
main = do
    print "infocus tests"
    hspec spec

spec :: Spec
spec = do
  describe "TheTest" TheTest.spec
  -- describe "GameClientSpec" GameClientSpec.spec