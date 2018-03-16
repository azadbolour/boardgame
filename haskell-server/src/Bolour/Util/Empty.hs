--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

module Bolour.Util.Empty (
    Empty(..)
  ) where

class Empty a
  where isEmpty :: a -> Bool



