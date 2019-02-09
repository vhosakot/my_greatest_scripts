package main

import (
 "fmt"
 _ "github.com/go-sql-driver/mysql"
 "github.com/jinzhu/gorm"
)

func run_sql_command(db *gorm.DB, sql_command string) {
	rows, _ := db.Raw(sql_command).Rows()
        cols, _ := rows.Columns()

        data := make(map[string]string)

        if rows.Next() {
                columns := make([]string, len(cols))
                columnPointers := make([]interface{}, len(cols))
                for i, _ := range columns {
                        columnPointers[i] = &columns[i]
                }

                rows.Scan(columnPointers...)

                for i, colName := range cols {
                        data[colName] = columns[i]
                }
        }
	fmt.Println("")
	fmt.Println(sql_command)
	fmt.Println("")
        fmt.Println(data)
	fmt.Println("")
}

func main() {
	db, err := gorm.Open("mysql", "ccp-user:kbjHv2M8ndpKNF3S8tE22ILDV@tcp(10.98.148.182:3306)/ccp")
	defer db.Close()

	if err != nil {
		fmt.Println("Failed to connect to database: ", err)
		return
	}

	rows, err := db.Raw("SELECT USER()").Rows()
	defer rows.Close()
	var col string
	for rows.Next() {
		err = rows.Scan(&col)
		if err != nil {
			fmt.Println("Failed to scan row: ", err)
		}
		fmt.Println("col: ", col)
	}

	run_sql_command(db, "SELECT USER()")
	run_sql_command(db, "SHOW GLOBAL VARIABLES LIKE 'tls_version'")
	run_sql_command(db, "SHOW SESSION STATUS LIKE 'Ssl_cipher'")
}
