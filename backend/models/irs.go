package models

// Tabel IRS
type IRS struct {
	IRS_ID      int    `json:"irs_id" db:"irs_id"`
	NIM         string `json:"nim" db:"nim"`
	Semester    int    `json:"semester" db:"semester"`
	TahunAjaran string `json:"tahun_ajaran" db:"tahun_ajaran"`
	Status      string `json:"status" db:"status"` // ENUM: "Pending", "Disetujui", "Ditolak"
}
