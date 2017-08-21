--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

module Main where

import Control.Concurrent (newMVar, takeMVar, putMVar)
import Control.Monad (forever)
import Control.Exception (bracket)

import Data.IORef

compute :: Int -> IO Int
compute i = return (2*i)

main :: IO ()

main = do
  var <- newIORef 10
  lock <- newMVar ()
  takeMVar lock
  val <- readIORef var
  writeIORef var 100
  putMVar lock ()
  print val
  result <- bracket (takeMVar lock) (putMVar lock) $ const $ do
    current <- readIORef var
    updated <- compute current
    writeIORef var updated
    return updated
  print result


