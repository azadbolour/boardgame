--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

module Bolour.Util.FileUtil (
    readDataFileAsLines
  ) where

-- Automagically-created module - specified as an external module in .cabal file.
import Paths_boardgame

-- TODO. What if file does not exist?

-- | Read lines of a data file.
readDataFileAsLines ::
  String            -- ^ The data file's path relative to the root of the project.
  -> IO [String]    -- ^ Returns the data file's line of text.

readDataFileAsLines path = do
  file <- getDataFileName path
  contents <- readFile file
  return $ lines contents

