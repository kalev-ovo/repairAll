package handler

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"repair_server/internal/service"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// UploadDir 上传文件存储目录（由 cmd/server 设置）
var UploadDir string

// allowedExts 允许的图片扩展名
var allowedExts = map[string]bool{
	".jpg": true, ".jpeg": true, ".png": true, ".gif": true, ".webp": true,
}

// UploadImage 上传图片（需登录）
// POST /api/v1/upload/image
func UploadImage(c *gin.Context) {
	claims := service.GetClaims(c)

	file, header, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "请选择文件"})
		return
	}
	defer file.Close()

	// 校验扩展名
	ext := strings.ToLower(filepath.Ext(header.Filename))
	if !allowedExts[ext] {
		c.JSON(http.StatusBadRequest, gin.H{"error": "不支持的图片格式，仅支持 jpg/png/gif/webp"})
		return
	}

	// 校验大小（最大 10MB）
	if header.Size > 10<<20 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "图片大小不能超过 10MB"})
		return
	}

	// 生成唯一文件名
	filename := fmt.Sprintf("%s_%d%s", uuid.New().String()[:8], claims.UserID, ext)

	// 按日期创建子目录
	dateDir := time.Now().Format("2006-01")
	saveDir := filepath.Join(UploadDir, dateDir)
	if err := os.MkdirAll(saveDir, 0755); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "创建目录失败"})
		return
	}

	savePath := filepath.Join(saveDir, filename)
	dst, err := os.Create(savePath)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "保存文件失败"})
		return
	}
	defer dst.Close()

	if _, err := io.Copy(dst, file); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "写入文件失败"})
		return
	}

	// 返回可访问的 URL
	url := fmt.Sprintf("/uploads/%s/%s", dateDir, filename)
	c.JSON(http.StatusOK, gin.H{"url": url, "filename": filename})
}
