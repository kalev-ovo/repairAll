package service

import "github.com/gin-gonic/gin"

// GetClaims 从 gin context 获取 JWT Claims
func GetClaims(c *gin.Context) *Claims {
	claims, exists := c.Get("claims")
	if !exists {
		return nil
	}
	return claims.(*Claims)
}
