package database

import (
	"fmt"
	"log"
	"time"

	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq" // PostgreSQL driver
	"github.com/yourorg/go-api-lab/internal/config"
)

// Connect opens a PostgreSQL connection pool and verifies it with a ping.
func Connect(cfg *config.Config) (*sqlx.DB, error) {
	dsn := fmt.Sprintf(
		"postgres://%s:%s@%s:%s/%s?sslmode=require",
		cfg.DBUser, cfg.DBPassword, cfg.DBHost, cfg.DBPort, cfg.DBName,
	)

	db, err := sqlx.Open("postgres", dsn)
	if err != nil {
		return nil, fmt.Errorf("sqlx.Open: %w", err)
	}

	// Connection pool settings
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(5 * time.Minute)

	// Retry ping up to 5 times (RDS may need a moment on cold start)
	for i := 0; i < 5; i++ {
		if err = db.Ping(); err == nil {
			break
		}
		log.Printf("Database not ready (attempt %d/5): %v", i+1, err)
		time.Sleep(2 * time.Second)
	}
	if err != nil {
		return nil, fmt.Errorf("database ping failed after retries: %w", err)
	}

	log.Println("Database connection established")
	return db, nil
}

// Migrate runs idempotent DDL migrations.
func Migrate(db *sqlx.DB) error {
	query := `
	CREATE TABLE IF NOT EXISTS users (
		id         SERIAL PRIMARY KEY,
		name       VARCHAR(100) NOT NULL,
		email      VARCHAR(100) UNIQUE NOT NULL,
		created_at TIMESTAMP DEFAULT NOW(),
		updated_at TIMESTAMP DEFAULT NOW()
	);`

	if _, err := db.Exec(query); err != nil {
		return fmt.Errorf("migration failed: %w", err)
	}

	log.Println("Database migration complete")
	return nil
}
