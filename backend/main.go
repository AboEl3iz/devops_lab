package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/joho/godotenv"
	"github.com/yourorg/go-api-lab/internal/config"
	"github.com/yourorg/go-api-lab/internal/database"
	"github.com/yourorg/go-api-lab/internal/router"
)

func main() {
	// Load .env file if present (local dev only; ignored in containers)
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found — using environment variables")
	}

	cfg := config.Load()

	db, err := database.Connect(cfg)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	if err := database.Migrate(db); err != nil {
		log.Fatalf("Migration failed: %v", err)
	}

	r := router.Setup(db)

	go func() {
		log.Printf("Starting server on port %s", cfg.Port)
		if err := r.Run(":" + cfg.Port); err != nil {
			log.Fatalf("Server failed: %v", err)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit
	log.Println("Shutting down server...")
}
