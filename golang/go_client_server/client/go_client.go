package main

import (
	"fmt"
	"time"

	"github.com/go-resty/resty/v2"
)

func main() {
	// Create a new Resty client
	client := resty.New()

	// Configure retry logic
	client.SetRetryCount(5). // Retry up to 10 times
					SetRetryWaitTime(2 * time.Second). // Wait 10 seconds between retries
					AddRetryCondition(func(r *resty.Response, err error) bool {
			// Retry on any network-related error
			if err != nil {
				fmt.Printf("Retrying due to error: %v\n", err)
				return true
			}
			// Retry if the HTTP status code is not success
			if !r.IsSuccess() {
				fmt.Printf("Retrying due to unexpected HTTP return code: %v\n", r.StatusCode())
				return true
			}
			return false
		})
	// Configure timeout
	client.SetTimeout(60 * time.Second)

	// Test the GET API
	fmt.Println("Testing GET API...")
	getResp, err := client.R().
		SetHeader("Accept", "application/json").
		Get("http://localhost:8080/get")

	if err != nil {
		fmt.Printf("Error calling GET API after retries: %v\n", err)
	}
	if getResp.StatusCode() != 200 {
		fmt.Printf("GET API failed after 10 retries. Response Code: %d, Response Body: %s\n", getResp.StatusCode(), getResp.String())
	}
	fmt.Printf("GET Response Code: %d\n", getResp.StatusCode())
	fmt.Printf("GET Response Body: %s\n", getResp.String())

	// Test the POST API
	fmt.Println("\n\nTesting POST API...")
	postPayload := map[string]string{
		"name": "Gopher",
	}

	postResp, err := client.R().
		SetHeader("Content-Type", "application/json").
		SetBody(postPayload).
		Post("http://localhost:8080/post")

	if err != nil {
		fmt.Printf("Error calling POST API after retries: %v\n", err)
	}
	if postResp.StatusCode() != 200 {
		fmt.Printf("POST API failed after 10 retries. Response Code: %d, Response Body: %s\n", postResp.StatusCode(), postResp.String())
	}
	fmt.Printf("POST Response Code: %d\n", postResp.StatusCode())
	fmt.Printf("POST Response Body: %s\n", postResp.String())
}
