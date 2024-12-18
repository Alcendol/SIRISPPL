package middleware

// import (
// 	"SIRIS/controller"
// 	"net/http"

// 	"github.com/golang-jwt/jwt/v4"
// 	"github.com/labstack/echo/v4"
// )

// func JWTMiddleware(next echo.HandlerFunc) echo.HandlerFunc {
// 	return func(c echo.Context) error {
// 		// Mengambil token dari header
// 		tokenString := c.Request().Header.Get("Authorization")

// 		// Memverifikasi token
// 		claims := &controller.JWTClaims{}
// 		token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
// 			return controller.JwtKey, nil
// 		})
// 		if err != nil || !token.Valid {
// 			return c.JSON(http.StatusUnauthorized, map[string]string{"message": "Unauthorized"})
// 		}

// 		// Menyimpan user ID di context untuk digunakan di controller lain
// 		c.Set("userID", claims.UserID)
// 		return next(c)
// 	}
// }
