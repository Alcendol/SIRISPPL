package models

type DosenPengampu struct {
	KodeMK string `json:"kode_mk" db:"kode_mk"`
	NIP    int    `json:"nip" db:"nip"`
	IdSem  string `json:"idsem" db:"idsem"`
}
