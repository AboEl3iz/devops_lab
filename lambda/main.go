package main

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

// Response is the JSON payload returned by the Lambda function.
type Response struct {
	Status      string `json:"status"`
	Message     string `json:"message"`
	Environment string `json:"environment"`
	Timestamp   string `json:"timestamp"`
}

// handler is the Lambda entry-point — handles API Gateway proxy requests.
func handler(ctx context.Context, req events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	resp := Response{
		Status:      "healthy",
		Message:     "Lambda function is running",
		Environment: os.Getenv("ENVIRONMENT"),
		Timestamp:   time.Now().UTC().Format(time.RFC3339),
	}

	body, err := json.Marshal(resp)
	if err != nil {
		return events.APIGatewayProxyResponse{StatusCode: 500}, fmt.Errorf("json.Marshal: %w", err)
	}

	return events.APIGatewayProxyResponse{
		StatusCode: 200,
		Headers: map[string]string{
			"Content-Type": "application/json",
		},
		Body: string(body),
	}, nil
}

func main() {
	fmt.Println("Starting Lambda function...")
	lambda.Start(handler)
}
