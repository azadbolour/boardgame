
{-# LANGUAGE EmptyDataDecls             #-}
{-# LANGUAGE FlexibleContexts           #-}
{-# LANGUAGE GADTs                      #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE MultiParamTypeClasses      #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE QuasiQuotes                #-}
{-# LANGUAGE TemplateHaskell            #-}
{-# LANGUAGE TypeFamilies               #-}

module Main where

import           Control.Monad.IO.Class  (liftIO)
import           Database.Persist
import           Database.Persist.Sqlite
import           Database.Persist.TH
import Control.Monad.Trans.Reader

share [mkPersist sqlSettings, mkMigrate "migrateAll"] [persistLowerCase|
Person
    name String
    age Int Maybe
    deriving Show
BlogPost
    title String
    authorId PersonId
    deriving Show
|]

-- Note. All the actions in this example take place under the umbrella of the single runSqlite.
-- TODO. Is there a way to remove the all-embracing umbrella for memory Sqlite.
-- Instead to have individual functions that work on the same database without
-- losing the connection. runSqlite upon return drops the database.
-- We need a way of doing an interaction and not losing the database,
-- and then later doing another interaction perhaps by a different. Our main
-- is not driven by Persistent, but by its own monad transformer stack.
main :: IO ()
main = runSqlite ":memory:" $ do
  runMigration migrateAll

  johnId <- insert $ Person "John Doe" $ Just 35
  janeId <- insert $ Person "Jane Doe" Nothing

  insert $ BlogPost "My fr1st post" johnId
  insert $ BlogPost "My second post" johnId

  oneJohnPost <- selectList [BlogPostAuthorId ==. johnId] [LimitTo 1]
  liftIO $ print (oneJohnPost :: [Entity BlogPost])

  john <- get johnId
  liftIO $ print (john :: Maybe Person)

  delete janeId
  deleteWhere [BlogPostAuthorId ==. johnId]

