package models

import "time"

// Tabel User_Role (Relasi Many-to-Many antara User dan Role)
type UserRole struct {
	UserID     int       `json:"user_id" db:"user_id"`
	RoleID     int       `json:"role_id" db:"role_id"`
	AssignedAt time.Time `json:"assigned_at" db:"assigned_at"`
}
