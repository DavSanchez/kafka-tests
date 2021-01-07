{-# LANGUAGE OverloadedStrings #-}

module Lib
  ( runConsumerExample,
  )
where

import Control.Exception (bracket)
import Control.Monad (replicateM_)
import Kafka.Consumer

-- Global consumer properties
consumerProps :: ConsumerProperties
consumerProps =
  brokersList ["localhost:9092"]
    <> groupId "consumer_example_group"
    <> noAutoCommit
    <> logLevel KafkaLogInfo

-- Subscription to topics
consumerSub :: Subscription
consumerSub =
  topics ["kafka-client-example-topic"]
    <> offsetReset Earliest

-- Running an example
runConsumerExample :: IO ()
runConsumerExample = bracket mkConsumer clConsumer runHandler >>= print
  where
    mkConsumer = newConsumer consumerProps consumerSub
    clConsumer (Left err) = pure (Left err)
    clConsumer (Right kc) = maybe (Right ()) Left <$> closeConsumer kc
    runHandler (Left err) = pure (Left err)
    runHandler (Right kc) = processMessages kc

processMessages :: KafkaConsumer -> IO (Either KafkaError ())
processMessages kafka = do
  replicateM_ 10 $ do
    msg <- pollMessage kafka (Timeout 1000)
    putStrLn $ "Message: " <> show msg
    err <- commitAllOffsets OffsetCommit kafka
    putStrLn $ "Offsets: " <> maybe "Committed." show err
  pure $ Right ()
