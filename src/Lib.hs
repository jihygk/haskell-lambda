{-# LANGUAGE OverloadedStrings #-}

module Lib where

import Network.Wreq
import Control.Lens
import Data.Aeson (toJSON)
import Data.Aeson.Lens (key, nth)
import qualified Data.ByteString.Lazy as B
import Control.Monad.Trans.AWS
import Control.Monad (liftM)
import Control.Monad
import Data.Time (getCurrentTime)
import Data.Time.ISO8601 (formatISO8601)
import Network.AWS.S3
import Network.AWS.Data
import System.IO
import Data.Text (Text, pack)

resource_url = "https://data.melbourne.vic.gov.au/resource/vh2v-4nfs.json" 
-- TODO: get from env
bucketName = "servian-city-of-melbourne-open-data"

getParkingSensorData :: IO B.ByteString
getParkingSensorData = do
    r <- get resource_url  -- get :: string -> IO (Response ByteString)
    pure (r ^. responseBody) 

getIsoTimeString :: IO String
getIsoTimeString = do
    t <- getCurrentTime
    pure $ formatISO8601 t

datedObjectName :: IO String
datedObjectName = do 
    l <- getIsoTimeString
    let x = concat ["on_street_parking_bay_sensors/", l, ".json"] 
    pure x

objectKey :: IO ObjectKey
objectKey = do 
    don <- datedObjectName 
    pure $ ObjectKey (pack don)

upObject :: IO PutObject
upObject = do
    on <- objectKey
    dt <- getParkingSensorData
    pure $ putObject (BucketName bucketName) on (toBody dt)

uploadObject :: PutObject -> IO ()
uploadObject o = do
    let r = Sydney :: Region
    lgr <- newLogger Debug stdout
    env <- newEnv Discover <&> set envLogger lgr . set envRegion r
    runResourceT . runAWST env $ do
        void . send $ o

run :: IO ()
run = do
    u <- upObject
    uploadObject u