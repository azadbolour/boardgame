--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

module BoardGame.Server.Domain.IndexedStripMatcher (
  ) where

import Data.Map (Map)

import BoardGame.Util.WordUtil (DictWord, LetterCombo, BlankCount, ByteCount)
import BoardGame.Server.Domain.Strip (Strip, GroupedStrips)
import BoardGame.Server.Domain.IndexedLanguageDictionary (IndexedLanguageDictionary)

-- | Find a best word match (if any) for a given strip.
findOptimalStripMatch ::
     IndexedLanguageDictionary  -- ^ the word dictionary to use
  -> Strip                      -- ^ the strip
  -> [LetterCombo]              -- ^ combinations of letters to try on the strip's blanks
  -> Maybe (Strip, DictWord)    -- ^ longest word found if any

findOptimalStripMatch dictionary strip combos = Nothing -- TODO. Implement.

-- | Find a best match (if any) for strips of a given length.
findOptimalMatchForStripsByLength ::
     IndexedLanguageDictionary
  -> Map BlankCount [Strip]         -- ^ strips of a given length grouped by number of blanks
  -> Map ByteCount [LetterCombo]    -- ^ combinations of letters grouped by count
  -> Maybe (Strip, DictWord)

findOptimalMatchForStripsByLength dictionary stripsByBlanks combosByLength = Nothing

-- | Find a best match (if any) for strips of at most a given length.
--   Recursive on the length limit.
--   Recursion allows us to break out as soon as we find a match at the limit.
--   Recursive matches will all be shorter and therefore inferior.
findOptimalMatchForStripsOfLimitedLength ::
     IndexedLanguageDictionary
  -> ByteCount
  -> GroupedStrips
  -> Maybe (Strip, DictWord)

-- TODO. Implement by using findOptimalMatchForStripsByLength and recursion.
findOptimalMatchForStripsOfLimitedLength dictionary maxCount groupedStrips = Nothing

findOptimalMatch ::
     IndexedLanguageDictionary
  -> GroupedStrips
  -> Maybe (Strip, DictWord)

findOptimalMatch dictionary groupedStrips = Nothing


