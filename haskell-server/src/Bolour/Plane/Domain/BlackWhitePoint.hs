--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Bolour.Plane.Domain.BlackWhitePoint (
    BlackWhitePoint(..)
  )
  where

import Bolour.Util.BlackWhite
import qualified Bolour.Util.Empty as Empty
import Bolour.Plane.Domain.Point (Point)

data BlackWhitePoint a = BlackWhitePoint {
    value :: BlackWhite a
  , point :: Point
}
deriving instance (Eq a) => Eq (BlackWhitePoint a)
deriving instance (Show a) => Show (BlackWhitePoint a)

instance Empty.Empty (BlackWhitePoint a)
  where isEmpty BlackWhitePoint {value} = Empty.isEmpty value


