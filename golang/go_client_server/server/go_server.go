package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	// "time"
)

// JSON response structure
type Response struct {
	Message string `json:"message"`
}

// JSON request structure
type Request struct {
	Name string `json:"name"`
}

func main() {
	http.HandleFunc("/get", func(w http.ResponseWriter, r *http.Request) {
		// Print the request details
		fmt.Println("\nReceived GET request:")
		fmt.Printf("Method: %s\n", r.Method)
		fmt.Printf("URL: %s\n", r.URL.String())
		fmt.Printf("Headers: %v\n", r.Header)

		// Temporary timeout
		// time.Sleep(65 * time.Second)

		// Temporarily, return an error
		// fmt.Println("Sending error from server")
		// http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		// return

		// Create a JSON response
		response := Response{
			Message: "Hello, this is a GET response!",
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(response)
	})

	http.HandleFunc("/post", func(w http.ResponseWriter, r *http.Request) {
		// Print the request details
		fmt.Println("\nReceived POST request:")
		fmt.Printf("Method: %s\n", r.Method)
		fmt.Printf("URL: %s\n", r.URL.String())
		fmt.Printf("Headers: %v\n", r.Header)

		// Temporary timeout
		// time.Sleep(65 * time.Second)

		// Temporarily, return an error
		// fmt.Println("Sending error from server")
		// http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		// return

		if r.Method != http.MethodPost {
			http.Error(w, "Invalid request method", http.StatusMethodNotAllowed)
			return
		}
		// Read and parse the JSON payload
		body, err := ioutil.ReadAll(r.Body)
		if err != nil {
			http.Error(w, "Failed to read request body", http.StatusBadRequest)
			return
		}
		fmt.Printf("Body: %s\n", string(body)) // Print the body of the POST request

		var req Request
		err = json.Unmarshal(body, &req)
		if err != nil {
			http.Error(w, "Failed to parse JSON", http.StatusBadRequest)
			return
		}
		// Respond with a message
		response := Response{
			Message: "Hello, " + req.Name + "!",
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(response)
	})

	// Start the server
	log.Println("Starting server on :8080...")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
