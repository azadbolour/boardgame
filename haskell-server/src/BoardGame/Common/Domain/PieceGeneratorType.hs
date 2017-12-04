
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}

module BoardGame.Common.Domain.PieceGeneratorType(
  PieceGeneratorType(..)
  )
  where

import GHC.Generics (Generic)
import Data.Aeson (FromJSON, ToJSON)
import Control.DeepSeq (NFData)

data PieceGeneratorType = Random | Cyclic
  deriving (Eq, Show, Generic, NFData)

instance FromJSON PieceGeneratorType
instance ToJSON PieceGeneratorType




