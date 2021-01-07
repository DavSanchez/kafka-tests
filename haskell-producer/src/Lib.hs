{-# LANGUAGE OverloadedStrings #-}

module Lib
  ( runProducerExample,
  )
where

import Control.Exception (bracket)
import Control.Monad (forM_)
import Data.ByteString (ByteString)
import Kafka.Producer

-- Global producer properties
producerProps :: ProducerProperties
producerProps = brokersList ["localhost:9092"] <> logLevel KafkaLogDebug

-- Topic to send messages to
targetTopic :: TopicName
targetTopic = "kafka-client-example-topic"

-- Run an example
runProducerExample :: IO ()
runProducerExample = bracket mkProducer clProducer runHandler >>= print
  where
    mkProducer = newProducer producerProps
    clProducer (Left _) = pure ()
    clProducer (Right prod) = closeProducer prod
    runHandler (Left err) = pure $ Left err
    runHandler (Right prod) = sendMessages prod

sendMessages :: KafkaProducer -> IO (Either KafkaError ())
sendMessages prod = do
  err1 <- produceMessage prod (mkMessage Nothing (Just "Test from producer"))
  forM_ err1 print

  err2 <- produceMessage prod (mkMessage (Just "key") (Just "Test from producer (with key)"))
  forM_ err2 print

  pure $ Right ()

mkMessage :: Maybe ByteString -> Maybe ByteString -> ProducerRecord
mkMessage k v =
  ProducerRecord
    { prTopic = targetTopic,
      prPartition = UnassignedPartition,
      prKey = k,
      prValue = v
    }
