module Main where

import Lib
import qualified Data.Aeson as Aeson
import AWSLambda
import AWSLambda.Events

main :: IO ()
main = lambdaMain handler


handler :: Aeson.Value -> IO ()
handler event = run

