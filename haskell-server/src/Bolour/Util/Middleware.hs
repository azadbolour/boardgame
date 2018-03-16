--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

{-# LANGUAGE OverloadedStrings #-}

module Bolour.Util.Middleware (
    optionsHandler
  , mkMiddlewareLogger
  , gameCorsMiddleware
  )
where

import qualified Network.HTTP.Types as HttpTypes
import Network.HTTP.Types.Header (ResponseHeaders)
import Network.Wai (Middleware)
import Network.Wai.Middleware.Cors as Cors
import qualified Network.Wai as Wai
import Network.Wai.Middleware.RequestLogger (logStdout, logStdoutDev)

import BoardGame.Server.Domain.ServerConfig (DeployEnv)
import qualified BoardGame.Server.Domain.ServerConfig as Env

-- | Intercept options responses to send the correct status and headers.
optionsHandler :: ResponseHeaders -> Middleware
optionsHandler optionsHeaders baseApp request responseCallback =
    if Wai.requestMethod request == HttpTypes.methodOptions then
        responseCallback $ Wai.responseLBS HttpTypes.status200 optionsHeaders ""
    else
        baseApp request responseCallback

-- TODO. This does not work and is a security risk anyway.
-- TODO. For development we need to server pages from the webpack server - but be able to access this server application.
-- TODO. What is the magic incantation for being able to do that. Read CORS.
addAllowOriginResponseHeader :: ResponseHeaders -> ResponseHeaders
addAllowOriginResponseHeader headers = ("Access-Control-Allow-Origin", "http://localhost:3000") : ("Vary", "Origin") : tail headers

mkMiddlewareLogger :: DeployEnv -> Middleware
mkMiddlewareLogger Env.Test = logStdoutDev
mkMiddlewareLogger Env.Dev = logStdoutDev
mkMiddlewareLogger Env.Prod = logStdout

-- TODO. This did not work for me. Got 400 errors with mode: 'cors' in headers from the fetch client.
-- What headers are required from the client to make this work?
gameCorsMiddleware :: Middleware
gameCorsMiddleware = cors (const $ Just gameCorsResourcePolicy)

gameCorsResourcePolicy :: Cors.CorsResourcePolicy
gameCorsResourcePolicy = Cors.CorsResourcePolicy
    {
      corsOrigins = Just (["http://localhost:3000"], True)
    , corsMethods = ["GET", "PUT", "POST"]
    , corsRequestHeaders = ["Content-Type"]
    , corsExposedHeaders = Nothing
    , corsMaxAge = Nothing
    , corsVaryOrigin = True
    , corsRequireOrigin = True
    , corsIgnoreFailures = False
    }

-- ("Access-Control-Allow-Headers", "Access-Control-Allow-Origin") :