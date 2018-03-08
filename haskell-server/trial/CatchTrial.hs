--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--


module Main where

import Control.Monad.IO.Class (MonadIO(..))
import Control.Monad.Except (ExceptT, runExceptT, throwError, catchError, withExceptT)

type IOExceptT left right = ExceptT left IO right

main :: IO ()

main = do
  what <- runExceptT $ doSomething 2
  print what
  print "done"

doSomething :: Int -> IOExceptT String Int
doSomething i = show `withExceptT` doIt i

doIt :: Int -> IOExceptT Int Int
doIt i = if i == 1 then return 1 else throwError 1



-- import Control.Exception
-- -- import Control.Monad.Except (ExceptT, ExceptT(ExceptT))
--
-- main :: IO ()
--
-- failing :: IO ()
-- failing = throw (ErrorCall "oops")
--
-- main = do
--   failing `catch` \e -> do
--     print (e :: SomeException)
--     print "done"





