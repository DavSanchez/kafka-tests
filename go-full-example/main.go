package main

import (
	"context"
	"fmt"
	"strconv"
	"time"

	"github.com/segmentio/kafka-go"
)

// Initializing topic and broker address
const (
	topic         = "kafka-client-example-topic" // Same as in Haskell clients
	brokerAddress = "localhost:9092"
)

func produce(ctx context.Context) {
	i := 0

	// Initialize the writer with address and topic
	w := kafka.NewWriter(kafka.WriterConfig{
		Brokers: []string{brokerAddress},
		Topic:   topic,
	})

	for {
		// Creating keyed messages with index
		err := w.WriteMessages(ctx, kafka.Message{
			Key: []byte(strconv.Itoa(i)),
			// Arbitrary message payload
			Value: []byte("This is message " + strconv.Itoa(i)),
		})
		if err != nil {
			panic("Could not write message " + err.Error())
		}

		// Log confirmation once message is written
		fmt.Println("Writes:", i)
		i++

		// Sleep for a second
		time.Sleep(time.Second)
	}
}

func consume(ctx context.Context) {
	r := kafka.NewReader(kafka.ReaderConfig{
		Brokers: []string{brokerAddress},
		Topic:   topic,
		GroupID: "consumer_example_group", // Same as Haskell consumer
		MinBytes: 5,
		// MaxBytes required if MinBytes set
		MaxBytes: 1e6,
		// MaxWait regardless of MinBytes
		MaxWait: 3 * time.Second,
	})

	for {
		// ReadMessage blocks until next event is received
		msg, err := r.ReadMessage(ctx)
		if err != nil {
			panic("Could not read message " + err.Error())
		}
		fmt.Println("Received:", string(msg.Value))
	}
}

func main() {
	// Create a new context
	ctx := context.Background()

	// As both produce and consume functions are blocking,
	// we produce the messages on a goroutine
	go produce(ctx)
	consume(ctx)
}
