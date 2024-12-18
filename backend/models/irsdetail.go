package models

// Tabel IRS_Detail (Relasi Many-to-Many antara IRS dan Mata_Kuliah)
type IRSDetail struct {
	IRSDetailID int    `json:"irs_detail_id" db:"irs_detail_id"`
	IRS_ID      int    `json:"irs_id" db:"irs_id"`
	KodeMK      string `json:"kode_mk" db:"kode_mk"`
	JadwalID    int    `json:"jadwal_id" db:"jadwal_id"`
}
