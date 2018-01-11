
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}

module BoardGame.Common.Domain.PieceProviderType(
  PieceProviderType(..)
  )
  where

import GHC.Generics (Generic)
import Data.Aeson (FromJSON, ToJSON)
import Control.DeepSeq (NFData)

data PieceProviderType = Random | Cyclic
  deriving (Eq, Show, Generic, NFData)

instance FromJSON PieceProviderType
instance ToJSON PieceProviderType




