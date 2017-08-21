--
-- Copyright 2017 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE DisambiguateRecordFields #-}
{-# LANGUAGE RecordWildCards #-}

module BoardGame.Server.Domain.EnglishDictionarySpec where

import Test.Hspec
import BoardGame.Server.Domain.LanguageDictionary (LanguageDictionary, LanguageDictionary(LanguageDictionary))
import qualified BoardGame.Server.Domain.LanguageDictionary as Dict

spec :: Spec
spec = do
  describe "test reading dictionary" $

    it "read it" $ do
      Dict.LanguageDictionary { words, isDictionaryWord } <- Dict.getDefaultDictionary
      let res = isDictionaryWord "WORD"
      res `shouldBe` True
      let res1 = isDictionaryWord "MACHINE"
      res1 `shouldBe` True
