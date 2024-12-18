package models

type User struct {
	UserID   uint   `json:"user_id"`
	Username string `json:"username"`
	Email    string `json:"email"`
	Password string `json:"password"` // Anda mungkin ingin mengenkripsi password di sini
}
