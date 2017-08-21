--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

module Main where

import Control.Concurrent (threadDelay)
import Control.Monad (forever)
import Control.Concurrent.Async (async, wait)

main :: IO ()

delay :: Int
delay = 1000000 * 2

someAction :: IO ()
someAction =
  forever $ do
    threadDelay delay
    print "done"

main = do
  future <- async (someAction)
  value <- wait future
  return ()

