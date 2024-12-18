package main

import (
	"SIRIS/controller"
	"net/http"

	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

func main() {
	e := echo.New()
	// Endpoint tanpa autentikasi
	e.POST("/login", controller.Login)
	e.POST("/register", controller.Register)

	// // Group route yang membutuhkan autentikasi
	// protected := e.Group("/api")
	// protected.Use(middleware.JWTMiddleware) // Hanya bisa diakses dengan JWT valid

	// Route mahasiswa
	e.GET("/mahasiswa/:nim/jadwal", controller.GetJadwalIRS)               // Mendapatkan jadwal untuk IRS
	e.POST("/mahasiswa/:nim/add-irs", controller.AddJadwalToIRS)           // Tambahkan jadwal ke IRS
	e.DELETE("/mahasiswa/:nim/remove-irs", controller.RemoveJadwalFromIRS) // Hapus jadwal dari IRS
	e.GET("/mahasiswa/jadwal", controller.GetJadwal)
	e.GET("/mahasiswa/:nim/mata-kuliah", controller.GetMataKuliahBySemester)
	e.GET("/mahasiswa/:kode_mk/jadwal-mata-kuliah", controller.GetJadwalByMataKuliah)
	e.GET("/mahasiswa/:nim/jadwal-irs", controller.GetIRSJadwal) //Mendapatkan jadwal IRS by semester
	e.GET("/mahasiswa/all-jadwal/:nim", controller.GetAllJadwalByMataKuliah)
	e.GET("/mahasiswa/daftar-matkul/:nim", controller.GetDaftarMataKuliah)
	e.GET("/mahasiswa/info-mahasiswa/:nim", controller.GetMahasiswaInfo)
	e.GET("/mahasiswa/:nim/irs-info", controller.GetIRSInfo)
	
	// Route dosen
	e.GET("/dosen/:nip/mahasiswa", controller.GetMahasiswaPerwalian) // Mendapatkan daftar mahasiswa perwalian
	e.POST("/mahasiswa/:nim/approve-irs", controller.ApproveIRS)
	e.GET("/dosen/:nip/angkatan", controller.GetAngkatanMahasiswaPerwalian)
	e.POST("/mahasiswa/:nim/unapprove-irs", controller.UnApproveIRS)
	e.GET("/dosen/:nip/:idsem", controller.GetAllStatusMahasiswaPerwalian)

	// Middleware untuk menangani CORS
	e.Use(middleware.CORSWithConfig(middleware.CORSConfig{
		AllowOrigins: []string{"http://localhost:8081"}, // ganti port sesuai yang digunakan Flutter
		AllowMethods: []string{http.MethodGet, http.MethodPost, http.MethodPut, http.MethodDelete},
	}))

	// Rute lainnya
	e.GET("/", func(c echo.Context) error {
		return c.String(http.StatusOK, "Welcome to SIRIS")
	})

	// Mulai server
	e.Logger.Fatal(e.Start(":8080"))
}
