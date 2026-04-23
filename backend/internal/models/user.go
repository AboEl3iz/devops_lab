package models

import "time"

// User represents a row in the users table.
type User struct {
	ID        int       `db:"id"         json:"id"`
	Name      string    `db:"name"       json:"name"`
	Email     string    `db:"email"      json:"email"`
	CreatedAt time.Time `db:"created_at" json:"created_at"`
	UpdatedAt time.Time `db:"updated_at" json:"updated_at"`
}

// CreateUserRequest is the request body for POST /api/users.
type CreateUserRequest struct {
	Name  string `json:"name"  binding:"required"`
	Email string `json:"email" binding:"required,email"`
}

// UpdateUserRequest is the request body for PUT /api/users/:id.
type UpdateUserRequest struct {
	Name  string `json:"name"`
	Email string `json:"email"`
}
