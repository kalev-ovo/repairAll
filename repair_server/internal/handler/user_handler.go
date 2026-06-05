package handler

import (
	"net/http"
	"strconv"

	"repair_server/internal/model"
	"repair_server/internal/repository"
	"repair_server/internal/service"

	"github.com/gin-gonic/gin"
)

// GetProfile 获取个人信息
func GetProfile(c *gin.Context) {
	claims := service.GetClaims(c)
	user, err := repository.GetUserByID(claims.UserID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "用户不存在"})
		return
	}

	resp := gin.H{"user": user}

	// 如果是师傅，附带师傅资料
	if user.Role == "worker" {
		worker, err := repository.GetWorkerByUserID(user.ID)
		if err == nil {
			resp["worker"] = worker
		}
	}

	c.JSON(http.StatusOK, resp)
}

// UpdateProfile 更新个人信息
func UpdateProfile(c *gin.Context) {
	claims := service.GetClaims(c)

	var req model.UpdateProfileReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "参数错误"})
		return
	}

	if err := repository.UpdateUser(claims.UserID, req.Name, req.Avatar); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "更新失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "更新成功"})
}

// SwitchRole 切换角色
func SwitchRole(c *gin.Context) {
	claims := service.GetClaims(c)

	newRole := "worker"
	if claims.Role == "worker" {
		newRole = "customer"
	}

	if err := repository.SwitchUserRole(claims.UserID, newRole); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "切换失败"})
		return
	}

	// 生成新 token（含新角色）
	token, err := service.GenerateToken(claims.UserID, claims.Phone, newRole)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "生成token失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "切换成功", "token": token, "role": newRole})
}

// UpdateWorkerProfile 更新师傅资料
func UpdateWorkerProfile(c *gin.Context) {
	claims := service.GetClaims(c)
	if claims.Role != "worker" {
		c.JSON(http.StatusForbidden, gin.H{"error": "仅师傅可操作"})
		return
	}

	var req model.WorkerProfileReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "参数错误"})
		return
	}

	w := &model.Worker{
		RealName:      req.RealName,
		IDCard:        req.IDCard,
		Skills:        req.Skills,
		YearsExp:      req.YearsExp,
		ServiceCity:   req.ServiceCity,
		Lat:           req.Lat,
		Lng:           req.Lng,
		ServiceRadius: req.ServiceRadius,
		Bio:           req.Bio,
	}
	if w.Skills == "" {
		w.Skills = "[]"
	}

	// 检查是否已有 worker 记录
	_, err := repository.GetWorkerByUserID(claims.UserID)
	if err != nil {
		// 创建
		w.UserID = claims.UserID
		if err := repository.CreateWorker(w); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "创建师傅资料失败"})
			return
		}
	} else {
		if err := repository.UpdateWorker(claims.UserID, w); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "更新失败"})
			return
		}
	}

	c.JSON(http.StatusOK, gin.H{"message": "更新成功"})
}

// GetWorkerDetail 查看师傅详情
func GetWorkerDetail(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "参数错误"})
		return
	}

	worker, err := repository.GetWorkerByUserID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "师傅不存在"})
		return
	}

	user, err := repository.GetUserByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "用户不存在"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"worker": worker, "user": gin.H{
		"name":   user.Name,
		"avatar": user.Avatar,
	}})
}

// GetWorkerStats 师傅收入统计
func GetWorkerStats(c *gin.Context) {
	claims := service.GetClaims(c)
	if claims.Role != "worker" {
		c.JSON(http.StatusForbidden, gin.H{"error": "仅师傅可查看收入统计"})
		return
	}

	stats, err := repository.GetWorkerStats(claims.UserID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询失败"})
		return
	}

	c.JSON(http.StatusOK, stats)
}
