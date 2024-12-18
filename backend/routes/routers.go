package routes

import (
	"SIRIS/controller"

	"github.com/labstack/echo/v4"
)

func Init() *echo.Echo {
	e := echo.New()
	// Endpoint tanpa autentikasi
	e.POST("/login", controller.Login)
	e.POST("/register", controller.Register)

	// // Group route yang membutuhkan autentikasi
	// protected := e.Group("/api")
	// protected.Use(middleware.JWTMiddleware) // Hanya bisa diakses dengan JWT valid

	// Route mahasiswa
	e.GET("/mahasiswa/:nim/jadwal", controller.GetJadwalIRS).Name = "get-jadwal-IRS-nim"        // Mendapatkan jadwal untuk IRS
	e.POST("/mahasiswa/irs", controller.AddJadwalToIRS).Name = "add-jadwal-IRS"             // Tambahkan jadwal ke IRS
	e.DELETE("/mahasiswa/irs/:nim", controller.RemoveJadwalFromIRS).Name = "remove-jadwal-IRS" // Hapus jadwal dari IRS
	e.GET("/mahasiswa/jadwal", controller.GetJadwal).Name = "get-jadwal-IRS"

	// Route dosen
	e.GET("/dosen/:nip/mahasiswa", controller.GetMahasiswaPerwalian) // Mendapatkan daftar mahasiswa perwalian

	return e
}
