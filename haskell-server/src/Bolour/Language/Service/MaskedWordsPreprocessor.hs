--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

module Main where

import System.Exit (die)
import Data.Set as Set
import System.Environment (getArgs)
import Control.Monad (when)
import qualified Bolour.Language.Util.WordUtil as WordUtil

main :: IO ()

-- | Compute all masked versions of a list of word masked with up to a
--   a given number of blanks. Does not de-duplicate the resulting set.
--   usage: MaskedWordPreprocessor wordsFile outFile maxBlanks
main = do
  args <- getArgs
  when (length args /= 3) $
    die "usage: MaskedWordPreprocessor wordsFile outFile maxBlanks"
  let [wordsFile, outFile, maxBlanksString] = args
      maxBlanks = read maxBlanksString :: Int
  content <- readFile wordsFile
  let words = lines content
  sequence_ $ writeMaskedWords outFile maxBlanks <$> words
  print "done"

writeMaskedWords :: String -> Int -> String -> IO ()
writeMaskedWords path maxBlanks word = do
  let maskedWords = WordUtil.maskWithBlanks word maxBlanks
  sequence_ $ writeLine <$> maskedWords
    where writeLine line = appendFile path (line ++ "\n")

--  maskedWords = Set.toList $ Dict.mkMaskedWords words maxBlanks
--  printIt s = appendFile outFile (s ++ "\n")
--  sequence_ $ printIt <$> maskedWords