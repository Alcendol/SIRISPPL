package routes

// import (
// 	"SIRIS/db"
// 	"database/sql"
// 	"encoding/base64"
// 	"log"
// 	"net/http"

// 	"github.com/labstack/echo/v4"
// )

// type LoginRequest struct {
// 	Email    string `json:"email"`
// 	Password string `json:"password"`
// }

// type Mahasiswa struct {
// 	Nama     string `json:"nama"`
// 	NIM      string `json:"nim"`
// 	Angkatan int    `json:"angkatan"`
// }

// type UserResponse struct {
// 	Role               string `json:"role"`
// 	Identifier         string `json:"identifier"`         // NIM atau NIP
// 	Name               string `json:"name"`               // Nama mahasiswa atau dosen
// 	Angkatan           string `json:"angkatan,omitempty"` // Angkatan hanya untuk mahasiswa
// 	Jurusan            string `json:"jurusan,omitempty"`  // jurusan mahasiswa
// 	Semester           int    `json:"semester,omitempty"` //
// 	Status             string `json:"status,omitempty"`   // status maha
// 	ProfileImage       []byte `json:"profile_image"`
// 	ProfileImageBase64 string `json:"profile_image_base64"`      // Base64 string
// 	DosenWaliName      string `json:"dosen_wali_name,omitempty"` // Nama dosen wali
// 	DosenWaliNIP       string `json:"dosen_wali_nip,omitempty"`  // NIP dosen wali
// }

// type RegisterRequest struct {
// 	Username   string `json:"username"`
// 	Email      string `json:"email"`
// 	Password   string `json:"password"`
// 	Role       string `json:"role"`       // 'Mahasiswa', 'Dosen', dll.
// 	Identifier string `json:"identifier"` // NIM untuk mahasiswa atau NIP untuk dosen
// 	Name       string `json:"name"`
// 	Angkatan   string `json:"angkatan"` // Hanya untuk mahasiswa
// 	Jabatan    string `json:"jabatan"`  // Hanya untuk dosen
// }

// func Register(c echo.Context) error {
// 	var req RegisterRequest
// 	if err := c.Bind(&req); err != nil {
// 		return c.JSON(http.StatusBadRequest, map[string]string{"message": "Invalid request"})
// 	}

// 	connection := db.CreateCon()

// 	// Simpan data pengguna ke tabel user
// 	result, err := connection.Exec("INSERT INTO user (username,email, password) VALUES (?,?,?)", req.Username, req.Email, req.Password)
// 	if err != nil {
// 		return c.JSON(http.StatusInternalServerError, map[string]string{"message": "Error creating user"})
// 	}

// 	// Ambil user_id yang baru saja dibuat
// 	userID, err := result.LastInsertId()
// 	if err != nil {
// 		return c.JSON(http.StatusInternalServerError, map[string]string{"message": "Error getting user ID"})
// 	}

// 	// Simpan data identitas berdasarkan role
// 	switch req.Role {
// 	case "Mahasiswa":
// 		_, err = connection.Exec("INSERT INTO mahasiswa (nim, user_id, nama, angkatan) VALUES (?, ?, ?, ?)", req.Identifier, userID, req.Name, req.Angkatan)
// 		if err != nil {
// 			return c.JSON(http.StatusInternalServerError, map[string]string{"message": "Error creating mahasiswa"})
// 		}
// 	case "Dosen":
// 		_, err = connection.Exec("INSERT INTO dosen (nip, user_id, nama, jabatan) VALUES (?, ?, ?, ?)", req.Identifier, userID, req.Name, req.Jabatan)
// 		if err != nil {
// 			return c.JSON(http.StatusInternalServerError, map[string]string{"message": "Error creating dosen"})
// 		}
// 	default:
// 		return c.JSON(http.StatusBadRequest, map[string]string{"message": "Invalid role"})
// 	}

// 	// Simpan hubungan antara pengguna dan role
// 	_, err = connection.Exec("INSERT INTO user_role (user_id, role_id) VALUES (?, (SELECT role_id FROM role WHERE role_name = ?))", userID, req.Role)
// 	if err != nil {
// 		return c.JSON(http.StatusInternalServerError, map[string]string{"message": "Error creating user role"})
// 	}

// 	return c.JSON(http.StatusCreated, map[string]string{"message": "User created successfully"})
// }

// func Login(c echo.Context) error {
// 	var req LoginRequest
// 	if err := c.Bind(&req); err != nil {
// 		return c.JSON(http.StatusBadRequest, map[string]string{"message": "Invalid request"})
// 	}

// 	// Verifikasi email dan password
// 	var passwordHash string
// 	connection := db.CreateCon()
// 	err := connection.QueryRow("SELECT password FROM user WHERE email = ?", req.Email).Scan(&passwordHash)
// 	if err != nil {
// 		if err == sql.ErrNoRows {
// 			return c.JSON(http.StatusUnauthorized, map[string]string{"message": "Invalid email or password"})
// 		}
// 		return c.JSON(http.StatusInternalServerError, map[string]string{"message": "Internal server error"})
// 	}

// 	// Mengambil informasi pengguna berdasarkan email
// 	var role string
// 	err = connection.QueryRow("SELECT r.role_name FROM user u JOIN user_role ur ON u.user_id = ur.user_id JOIN role r ON ur.role_id = r.role_id WHERE u.email = ?", req.Email).Scan(&role)
// 	if err != nil {
// 		return c.JSON(http.StatusInternalServerError, map[string]string{"message": "Internal server error"})
// 	}

// 	// Mempersiapkan response berdasarkan role
// 	var userResponse UserResponse
// 	switch role {
// 	case "Mahasiswa":
// 		err = connection.QueryRow(`
// 			SELECT m.nim, m.nama, m.angkatan,m.jurusan, m.semester,m.status,d.nama AS dosen_wali_name, d.nip AS dosen_wali_nip , m.gambar
// 			FROM mahasiswa m
// 			JOIN user u ON m.user_id = u.user_id
// 			LEFT JOIN dosen d ON m.nip_wali = d.nip
// 			WHERE u.email = ?`, req.Email).
// 			Scan(&userResponse.Identifier, &userResponse.Name, &userResponse.Angkatan, &userResponse.Jurusan, &userResponse.Semester, &userResponse.Status, &userResponse.DosenWaliName, &userResponse.DosenWaliNIP, &userResponse.ProfileImage)

// 		if err != nil {
// 			if err == sql.ErrNoRows {
// 				return c.JSON(http.StatusNotFound, map[string]string{"message": "User not found"})
// 			}
// 			log.Println("Query Error:", err) // Tambahkan log error untuk lebih jelas
// 			return c.JSON(http.StatusInternalServerError, map[string]string{"message": "Internal server error"})
// 		}
// 		userResponse.Role = "Mahasiswa"
// 		userResponse.ProfileImageBase64 = base64.StdEncoding.EncodeToString(userResponse.ProfileImage)
// 	case "Dosen":
// 		err = connection.QueryRow("SELECT d.nip, d.nama FROM dosen d JOIN user u ON d.user_id = u.user_id WHERE u.email = ?", req.Email).
// 			Scan(&userResponse.Identifier, &userResponse.Name)
// 		if err != nil {
// 			return c.JSON(http.StatusInternalServerError, map[string]string{"message": "Internal server error"})
// 		}
// 		userResponse.Role = "Dosen"
// 	default:
// 		return c.JSON(http.StatusUnauthorized, map[string]string{"message": "User role not found"})
// 	}

// 	// Mengembalikan response dengan informasi pengguna
// 	return c.JSON(http.StatusOK, userResponse)
// }
