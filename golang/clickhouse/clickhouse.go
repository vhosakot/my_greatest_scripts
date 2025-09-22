package main

import (
	"fmt"
	"io"
	"net/http"
	"strings"
)

// Post HTTP request to ClickHouse
func postHttpRequest(query string) []byte {
	var req, err = http.NewRequest("POST", "http://localhost:8123/", strings.NewReader(query))
	if err != nil {
		panic(err)
	}
	req.SetBasicAuth("default", "password1234")
	req.Header.Set("Content-Type", "text/plain")
	// Post HTTP request
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		panic(err)
	}
	// fmt.Printf("resp: %v\n", resp)
	body, _ := io.ReadAll(resp.Body)
	// fmt.Println("Body:\n" + string(body))
	defer resp.Body.Close()

	if query == "OPTIMIZE TABLE users FINAL" {
		fmt.Println("        Response:", resp.Status)
	} else {
		fmt.Println("Response:", resp.Status)
	}
	if resp.StatusCode != http.StatusOK {
		panic("ERROR: Operation failed for query: " + query)
	}
	return body
}

// Manually force cleanup or merge outdated / old / deleted rows in the 'users' table
func cleanupOutdatedRows() {
	query := "OPTIMIZE TABLE users FINAL"
	fmt.Println("        ======== cleanupOutdatedRows() ========")
	postHttpRequest(query)
	fmt.Println("        Outdated rows cleaned up successfully!")
}

// Create table in ClickHouse database
func createTable() {
	query := `CREATE TABLE IF NOT EXISTS users (
        name String,
        age UInt8,
        location String
    ) ENGINE = ReplacingMergeTree()
    ORDER BY name
    SETTINGS cleanup_delay_period = 0;`

	fmt.Println("\n======== createTable() ========")
	postHttpRequest(query)
	fmt.Println("'users' table created successfully!")
}

// Check if table exists in ClickHouse database
func checkTableExists() {
	query := "SELECT name FROM system.tables WHERE name = 'users' AND database = 'default'"
	fmt.Println("\n======== checkTableExists() ========")
	resp := postHttpRequest(query)
	if string(resp) == "" {
		fmt.Println("Table 'users' does NOT exist.")
	} else {
		fmt.Println("Table 'users' exists.")
	}
}

// Count rows in 'users' table
func countRows() {
	// SQL query to count rows
	query := "SELECT count() FROM users"
	fmt.Println("\n======== countRows() ========")
	resp := postHttpRequest(query)
	fmt.Printf("Row count in 'users' table: %s", string(resp))
}

// Read rows from 'users' table
func readRows() {
	// SQL query to read all rows
	query := "SELECT name, age, location FROM users FORMAT TabSeparated"
	fmt.Println("\n======== readRows() ========")
	resp := postHttpRequest(query)
	fmt.Printf("Rows from 'users' table:    ")
	if len(resp) == 0 {
		fmt.Println("No rows found.")
	} else {
		fmt.Println(strings.TrimSuffix(string(resp), "\n"))
	}
}

// Insert row into 'users' table
func insertRow() {
	// JSON data to insert
	data := `{"name": "John", "age": 50, "location": "boston"}`
	// Full query with JSONEachRow format
	query := "INSERT INTO users FORMAT JSONEachRow\n" + data
	fmt.Println("\n======== insertRow() ========")
	postHttpRequest(query)
	cleanupOutdatedRows()
	fmt.Println("Row inserted into 'users' table successfully!")
}

// Update row in 'users' table
func updateRow() {
	// Updated data for user "John"
	data := `{"name": "John", "age": 51, "location": "cambridge"}`
	// ReplacingMergeTree will keep the latest version
	query := "INSERT INTO users FORMAT JSONEachRow\n" + data
	fmt.Println("\n======== updateRow() ========")
	postHttpRequest(query)
	cleanupOutdatedRows()
	fmt.Println("Row updated in 'users' table successfully!")
}

// Read updated row from 'users' table
func readUpdatedRow() {
	query := "SELECT name, age, location FROM users FINAL WHERE name = 'John'"
	fmt.Println("\n======== readUpdatedRow() ========")
	resp := postHttpRequest(query)
	fmt.Println("Updated Row:    " + strings.TrimSuffix(string(resp), "\n"))
}

// Delete row from 'users' table
func deleteRow() {
	// Simulate deletion by inserting a blank version of the row
	data := `{"name": "John", "age": 0, "location": ""}`
	query := "INSERT INTO users FORMAT JSONEachRow\n" + data
	fmt.Println("\n======== deleteRow() ========")
	postHttpRequest(query)
	cleanupOutdatedRows()
	fmt.Println("Row deleted from 'users' table successfully!")

	//////// Sql query to find the Primary Key for the 'users' table
	// SELECT primary_key FROM system.tables WHERE name = 'users' AND database = 'default';
	//////// Sql query to find the rows where location is not empty
	// SELECT * FROM users WHERE location != '';
}

// Truncate the 'users' table (delete all rows) and drop the table
func truncateAndDropTable() {
	// Truncate the table (delete all rows)
	truncateQuery := "TRUNCATE TABLE users"
	// Drop the table
	dropQuery := "DROP TABLE users"
	queries := []string{truncateQuery, dropQuery}
	fmt.Println("\n======== truncateAndDropTable() ========")
	for _, query := range queries {
		postHttpRequest(query)
	}
	fmt.Println("Table 'users' truncated and dropped successfully!")
}

// Main function
func main() {
	createTable()
	checkTableExists()
	countRows()
	readRows()
	insertRow()
	countRows()
	readRows()
	updateRow()
	countRows()
	readRows()
	readUpdatedRow()
	deleteRow()
	countRows()
	readRows()
	readUpdatedRow()
	truncateAndDropTable()
	checkTableExists()
}
