package router

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/jmoiron/sqlx"
	"github.com/yourorg/go-api-lab/internal/handlers"
)

// Setup creates and configures the Gin router with all application routes.
func Setup(db *sqlx.DB) *gin.Engine {
	r := gin.Default() // includes Logger and Recovery middleware

	h := handlers.NewHandler(db)

	// Health check — used by load balancers and CI smoke tests
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "ok",
			"service": "go-api-lab",
		})
	})

	// API routes
	api := r.Group("/api")
	{
		users := api.Group("/users")
		{
			users.GET("", h.ListUsers)
			users.GET("/:id", h.GetUser)
			users.POST("", h.CreateUser)
			users.PUT("/:id", h.UpdateUser)
			users.DELETE("/:id", h.DeleteUser)
		}
	}

	return r
}
