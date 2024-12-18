package db

import (
	"SIRIS/config"
	"database/sql"

	_ "github.com/go-sql-driver/mysql"
)

var db *sql.DB
var err error

func init() {
	conf := config.GetConfig()
	connectionString := conf.DB_USERNAME + ":" + conf.DB_PASSWORD + "@tcp(" + conf.DB_HOST + ":" + conf.DB_PORT + ")/" + conf.DB_NAME

	db, err = sql.Open("mysql", connectionString)

	if err != nil {
		panic("Connection error")
	}
	err := db.Ping()

	if err != nil {
		panic("DSN ERROR")
	}

}

func CreateCon() *sql.DB {
	return db
}
