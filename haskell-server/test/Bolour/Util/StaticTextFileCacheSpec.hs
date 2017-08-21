--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

module Bolour.Util.StaticTextFileCacheSpec where

import Test.Hspec
import Control.Monad.Except (runExceptT)
import qualified Bolour.Util.StaticTextFileCache as Cache

spec :: Spec
spec =
  describe "read 2 files into the cache" $
    it "read 2 files" $ do
      cache <- Cache.mkCache 2 id
      Right lines1 <- runExceptT $ Cache.get cache "test-data/file1.txt"
      print lines1
      Right lines2 <- runExceptT $ Cache.get cache "test-data/file2.txt"
      print lines2
      Right lines2 <- runExceptT $ Cache.get cache "test-data/file2.txt"
      print lines2
      Right lines1 <- runExceptT $ Cache.get cache "test-data/file1.txt"
      print lines1
      Left err <- runExceptT $ Cache.get cache "test-data/does-not-exist"
      print err
      -- Cache is full at this point.
      Left err <- runExceptT $ Cache.get cache "test-data/file3.txt"
      print err

