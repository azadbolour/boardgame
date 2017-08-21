--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

module Main where

import Control.Exception
-- import Control.Monad.Except (ExceptT, ExceptT(ExceptT))

main :: IO ()

failing :: IO ()
failing = throw (ErrorCall "oops")

main = do
  failing `catch` \e -> do
    print (e :: SomeException)
    print "done"





