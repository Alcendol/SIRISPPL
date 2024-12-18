package models

type Dosen struct {
	NIP     string `json:"nip" db:"nip"`
	UserID  int    `json:"user_id" db:"user_id"`
	Nama    string `json:"nama" db:"nama"`
	Jabatan string `json:"jabatan" db:"jabatan"` // ENUM: "Pembimbing Akademik", "Dekan", "Kaprodi"
}
