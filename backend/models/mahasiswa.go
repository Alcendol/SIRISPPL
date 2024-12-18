package models

// Tabel Mahasiswa
type Mahasiswa struct {
	NIM                string `json:"nim" db:"nim"`
	UserID             int    `json:"user_id" db:"user_id"`
	Nama               string `json:"nama" db:"nama"`
	Angkatan           int    `json:"angkatan" db:"angkatan"`
	Jurusan            string `json:"jurusan,omitempty"`  // jurusan mahasiswa
	Semester           int    `json:"semester,omitempty"` //
	Status             string `json:"status,omitempty"`   // status maha
	NipWali            string `json:"nip_wali" db:"nip_wali"`
	ProfileImage       []byte `json:"profile_image"`
	ProfileImageBase64 string `json:"profile_image_base64"` // Base64 string
}
