--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

module Bolour.Util.MiscUtil (
    debug
  , setListElement
  , isPositive
  , nonPositive
  , fromRight
  , mkUuid
  , returnR
  , returnL
  , isAlphaNumString
  , contiguous
  , maybeToEither
  , mapMaybeToEither
  , IOEither
  , IOExceptT
  , mapFromValueList
  , zipMaps
  , inverseMultiValuedMapping
) where

import Data.Char (isAlphaNum)
import Data.Map (Map)
import qualified Data.Map as Map
import qualified Data.List as List
import qualified Data.Maybe as Maybe
import Debug.Trace
import Data.UUID
import Data.UUID.V4
import Control.Monad.IO.Class (MonadIO(..))
import Control.Monad.Except (ExceptT)

-- | Shorthand for tracing.
debug :: String -> a -> a
debug message = trace ("TRACE: " ++ message)

-- TODO. Is it easier to use lenses here for setting list elements?

setListElement :: [element] -> Int -> element -> [element]
setListElement [] _ _ = []                     -- TODO. Exception??
setListElement list 0 element = element : tail list
setListElement list n element = head list : setListElement (tail list) (n - 1) element

isPositive :: (Num num, Ord num) => num -> Bool
isPositive x = (signum x) > 0

nonPositive :: (Num num, Ord num) => num -> Bool
nonPositive = not . isPositive

fromRight :: (Show left) => Either left right -> right
fromRight = either (error . show) id

-- | Get a uuid.
mkUuid :: (MonadIO m) => m String
mkUuid = do
  uuid <- liftIO nextRandom
  return $ toString uuid

returnR :: (Monad monad) => a -> monad (Either e a)
returnR value = return $ Right value
returnL :: (Monad monad) => e -> monad (Either e a)
returnL error = return $ Left error

-- | Convert a may to an Either supplying an error for Nothing.
maybeToEither :: error -> Maybe substrate -> Either error substrate
maybeToEither error may =
  case may of
    Nothing -> Left error
    Just substrate -> Right substrate

-- | Convert a maybe within a monad to an error within the monad.
mapMaybeToEither :: (Monad m) => error -> m (Maybe substrate) -> m (Either error substrate)
mapMaybeToEither error monad =
  maybeToEither error <$> monad

isAlphaNumString :: String -> Bool
isAlphaNumString s = all isAlphaNum s

-- | Does list of integers represent successive values?
contiguous :: [Int] -> Bool
contiguous [] = True
contiguous [x] = True
contiguous (x:y:ys) = (y == x + 1) && contiguous (y:ys)

type IOEither left right = IO (Either left right)
type IOExceptT left right = ExceptT left IO right

mapFromValueList :: (Ord key) => (value -> key) -> [value] -> Map key [value]
mapFromValueList keyMaker values =
  let pairMaker value = (keyMaker value, [value])
      pairs = pairMaker <$> values
  in Map.fromListWith (++) pairs

lookupJust :: (Ord key) => key -> Map key value -> value
lookupJust key map = Maybe.fromJust $ Map.lookup key map

zipMaps :: (Ord key) => Map key value1 -> Map key value2 -> Map key (value1, value2)
zipMaps map1 map2 =
  let keys1 = Map.keys map1
      keys2 = Map.keys map2
      commonKeys = List.intersect keys1 keys2
      zipper key = (key, (lookupJust key map1, lookupJust key map2))
  in Map.fromList $ zipper <$> commonKeys

inverseMultiValuedMapping :: Ord b => (a -> [b]) -> [a] -> Map.Map b [a]
inverseMultiValuedMapping mapping as =
  let inversePairWithMappedValue a = (\b -> (b, [a])) <$> mapping a
      pairs = as >>= inversePairWithMappedValue
  in
    Map.fromListWith (++) pairs








