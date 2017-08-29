module BoardGame.Server.Domain.Strip (
    Strip
  , GroupedStrips
  ) where

import Data.ByteString.Char8 (ByteString)
import qualified Data.ByteString.Char8 as ByteString
import Data.Map (Map)
import qualified Data.Map as Map

import BoardGame.Util.WordUtil (DictWord, LetterCombo, BlankCount, ByteCount)
import BoardGame.Common.Domain.Point (Axis, Coordinate)

-- | A horizontal or vertical strip of the board.
data Strip = Strip {
    axis :: Axis              -- ^ direction of the strip - X = horizontal, Y = vertical - TODO. Consistent use of axis.
  , lineNumber :: Coordinate  -- ^ position of the strip's line within all lines in teh same direction
  , begin :: Coordinate       -- ^ beginning index of the strip
  , end :: Coordinate         -- ^ ending index of the strip
  , content :: ByteString     -- ^ letters and blanks
  , letters :: LetterCombo    -- ^ existing combination of letters in the strip
  , blanks :: BlankCount      -- ^ number of blank spaces in the strip
} deriving (Eq, Show)

-- | Strips of a a board grouped by length and by number of blanks.
--   They are grouped by length to allow longer strips to be matched first (they are of highest value).
--   They are grouped by the number of blanks so that a given combination of tray letters can be tested
--   only against those strips that have the right number of blanks (= the size of the combination).
type GroupedStrips = Map ByteCount (Map BlankCount [Strip])

-- | Does a given word fit exactly in a strip.
--   The word have have been chosen to have the combination of the strip's letters
--   and a combination of tray letters equal in size to the strip's blanks.
--   The word would have been some permutation of the combined strip and tray letters.
--   That permutation may or may not match the strips existing letters.
matchWordToStrip :: Strip -> DictWord -> Maybe (Strip, DictWord)

matchWordToStrip strip word = Nothing

-- | Get one matching word to the strip among the given words.
--   All the words being tested would have had the same length.
--   So they would all have the same score and any one will do.
matchWordsToStrip :: Strip -> [DictWord] -> Maybe (Strip, DictWord)

matchWordsToStrip strip words = Nothing





