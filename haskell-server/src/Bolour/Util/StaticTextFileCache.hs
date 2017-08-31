--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

module Bolour.Util.StaticTextFileCache (
    mkCache
  , get
  , TextFileCacheType
  , LinesExceptT
) where

-- import Control.Monad (join)
import Control.Exception (SomeException)
import Control.Exception.Enclosed (catchAny)
import Control.Monad.Except (ExceptT(ExceptT), MonadError(..))
import Bolour.Util.Cache (Cache)
import qualified Bolour.Util.Cache as Cache
import Bolour.Util.MiscUtil (IOEither, IOExceptT)

-- Cache of lines of text files.

type TextFileCacheType = (Cache String [String], String -> String)
type LinesExceptT = IOExceptT String [String]

mkCache :: Int -> (String -> String) -> IO TextFileCacheType
mkCache capacity lineTransformer = do
  innerCache <- Cache.mkCache capacity
  return (innerCache, lineTransformer)

get :: TextFileCacheType -> String -> LinesExceptT
-- get cache path = return $ Right [] -- TODO. Implement get.
-- TODO. Check capacity.
get (cache @ (innerCache, transformer)) path = Cache.lookup path innerCache `catchError` (\_ -> readTextFile innerCache path transformer)

readTextFile :: Cache String [String] -> String -> (String -> String) -> LinesExceptT
readTextFile cache path transformer = do
  lines <- ExceptT $ catchAny (readTextInternal path) showException
  let transformedLines = transformer <$> lines
  Cache.insert path transformedLines cache
  return transformedLines

readTextInternal :: String -> IOEither String [String]
readTextInternal path = do
  print $ "reading file: " ++ path
  contents <- readFile path
  return $ Right $ lines contents

showException :: SomeException -> IOEither String [String]
showException someExc = return $ Left $ show someExc


