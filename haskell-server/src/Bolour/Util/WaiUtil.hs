--
-- Copyright 2017-2018 Azad Bolour
-- Licensed under GNU Affero General Public License v3.0 -
--   https://github.com/azadbolour/boardgame/blob/master/LICENSE.md
--

module Bolour.Util.WaiUtil (
    startWaiApp
  , endWaiApp
  , openTestSocket
) where

import Control.Concurrent (ThreadId)
import qualified Control.Concurrent as Concurrent

import Network.Socket (
    Socket
  , Family(AF_INET)
  , SockAddr(SockAddrInet)
  , SocketType(Stream)
 )
import qualified Network.Socket as Socket

import Network.Wai (Application)

import Network.Wai.Handler.Warp (Port)
import qualified Network.Wai.Handler.Warp as Warp

import Servant.Common.BaseUrl

-- | Inet address of socket.
type Addr = String

localhost :: Addr
localhost = "127.0.0.1"

startWaiApp :: IO Application -> IO (ThreadId, BaseUrl)
startWaiApp application = do
    theApplication <- application
    (port, socket) <- openTestSocket localhost
    let settings = Warp.setPort port Warp.defaultSettings
    thread <- Concurrent.forkIO $ Warp.runSettingsSocket settings socket theApplication
    return (thread, BaseUrl Http "localhost" port "")

endWaiApp :: (ThreadId, BaseUrl) -> IO ()
endWaiApp (thread, _) = Concurrent.killThread thread

openTestSocket :: Addr -> IO (Port, Socket)
openTestSocket host = do
  s <- Socket.socket AF_INET Stream Socket.defaultProtocol
  localhost <- Socket.inet_addr host
  Socket.bind s (SockAddrInet Socket.aNY_PORT localhost)
  Socket.listen s 1
  port <- Socket.socketPort s
  return (fromIntegral port, s)



