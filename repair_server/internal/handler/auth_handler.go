package handler

import (
	"net/http"

	"repair_server/internal/model"
	"repair_server/internal/service"

	"github.com/gin-gonic/gin"
)

// SendCode 发送验证码
func SendCode(c *gin.Context) {
	var req model.SendCodeReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "手机号不能为空"})
		return
	}

	code, err := service.GenerateAndSendCode(req.Phone)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "发送失败"})
		return
	}

	// 开发阶段返回验证码（生产去掉）
	c.JSON(http.StatusOK, gin.H{"message": "验证码已发送", "code": code})
}

// Login 登录/注册
func Login(c *gin.Context) {
	var req model.LoginReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "参数错误"})
		return
	}

	resp, err := service.Login(req.Phone, req.Code)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, resp)
}

// Register 注册（指定角色）
func Register(c *gin.Context) {
	var req model.RegisterReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "参数错误，role需为customer或worker"})
		return
	}

	resp, err := service.Register(req.Phone, req.Code, req.Role)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, resp)
}
