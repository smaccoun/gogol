{-# LANGUAGE OverloadedStrings #-}

-- |
-- Module      : Network.Google.Internal.Body
-- Copyright   : (c) 2015-2016 Brendan Hay
-- License     : Mozilla Public License, v. 2.0.
-- Maintainer  : Brendan Hay <brendan.g.hay@gmail.com>
-- Stability   : provisional
-- Portability : non-portable (GHC extensions)
--
module Network.Google.Internal.Body where

import           Control.Monad.IO.Class (MonadIO (..))
import           Data.Conduit.Binary    (sourceFile)
import           Data.Maybe             (fromMaybe)
import qualified Data.Text              as Text
import           Network.Google.Types   (Body (..))
import           Network.HTTP.Conduit   (RequestBody, requestBodySource)
import           Network.HTTP.Media     (MediaType, parseAccept, (//))
import qualified Network.Mime           as MIME
import           System.IO

-- | Convenience function for obtaining the size of a file.
getFileSize :: MonadIO m => FilePath -> m Integer
getFileSize f = liftIO (withBinaryFile f ReadMode hFileSize)

getMIMEType :: FilePath -> MediaType
getMIMEType =
      fromMaybe ("application" // "octet-stream")
    . parseAccept
    . MIME.defaultMimeLookup
    . Text.takeWhileEnd (/= '/')
    . Text.pack

-- | Construct a 'Body' from a 'FilePath'.
--
-- This attempts to guess the MIME type from the file extension,
-- you can use "Network.Google.Types.bodyContentType" to set a MIME type explicitly.
sourceBody :: MonadIO m => FilePath -> m Body
sourceBody f = do
    n <- getFileSize f
    pure $ Body
        (getMIMEType f)
        (requestBodySource (fromIntegral n) (sourceFile f))
