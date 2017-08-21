--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE ScopedTypeVariables #-}

module Main where

import Data.IORef

main :: IO ()

add1 :: IORef Int -> IO ()
add1 ref = modifyIORef' ref (+1)

main = do
  box <- newIORef 4
  val1 <- readIORef box
  print val1
  add1 box
  readIORef box >>= print