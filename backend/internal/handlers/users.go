package handlers

import (
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jmoiron/sqlx"
	"github.com/yourorg/go-api-lab/internal/models"
)

// Handler holds shared dependencies for all HTTP handlers.
type Handler struct {
	DB *sqlx.DB
}

// NewHandler creates a Handler with the given database connection.
func NewHandler(db *sqlx.DB) *Handler {
	return &Handler{DB: db}
}

// ListUsers godoc
// GET /api/users — returns all users ordered by id.
func (h *Handler) ListUsers(c *gin.Context) {
	var users []models.User
	if err := h.DB.Select(&users, `SELECT id, name, email, created_at, updated_at FROM users ORDER BY id`); err != nil {
		log.Printf("ListUsers: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to retrieve users"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": users})
}

// GetUser godoc
// GET /api/users/:id — returns a single user by id.
func (h *Handler) GetUser(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid user id"})
		return
	}

	var user models.User
	if err := h.DB.Get(&user, `SELECT id, name, email, created_at, updated_at FROM users WHERE id = $1`, id); err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": user})
}

// CreateUser godoc
// POST /api/users — inserts a new user and returns it.
func (h *Handler) CreateUser(c *gin.Context) {
	var req models.CreateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var user models.User
	err := h.DB.QueryRowx(
		`INSERT INTO users (name, email) VALUES ($1, $2)
		 RETURNING id, name, email, created_at, updated_at`,
		req.Name, req.Email,
	).StructScan(&user)
	if err != nil {
		log.Printf("CreateUser: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create user"})
		return
	}
	c.JSON(http.StatusCreated, gin.H{"data": user})
}

// UpdateUser godoc
// PUT /api/users/:id — updates name and/or email of an existing user.
func (h *Handler) UpdateUser(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid user id"})
		return
	}

	var req models.UpdateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var user models.User
	err = h.DB.QueryRowx(
		`UPDATE users
		 SET name       = COALESCE(NULLIF($1,''), name),
		     email      = COALESCE(NULLIF($2,''), email),
		     updated_at = $3
		 WHERE id = $4
		 RETURNING id, name, email, created_at, updated_at`,
		req.Name, req.Email, time.Now().UTC(), id,
	).StructScan(&user)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "user not found or update failed"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": user})
}

// DeleteUser godoc
// DELETE /api/users/:id — removes a user by id.
func (h *Handler) DeleteUser(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid user id"})
		return
	}

	result, err := h.DB.Exec(`DELETE FROM users WHERE id = $1`, id)
	if err != nil {
		log.Printf("DeleteUser: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to delete user"})
		return
	}

	rows, _ := result.RowsAffected()
	if rows == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "user not found"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"data": gin.H{"deleted_id": id}})
}
