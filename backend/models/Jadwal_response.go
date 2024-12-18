package models

type JadwalResponse struct {
	JadwalID    int    `json:"jadwal_id"`
	KodeMK      string `json:"kode_mk"`
	NipPengajar string `json:"nip_pengajar"`
	KodeRuangan string `json:"kode_ruangan"`
	Hari        string `json:"hari"`
	JamMulai    string `json:"jam_mulai"`
	JamSelesai  string `json:"jam_selesai"`
	NamaMK      string `json:"nama_mk"`
	SKS         int    `json:"sks"`
	Status      string `json:"status"`
}
