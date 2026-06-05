package handler

import (
	"fmt"
	"net/http"
	"strconv"

	"repair_server/internal/model"
	"repair_server/internal/repository"
	"repair_server/internal/service"

	"github.com/gin-gonic/gin"
)

// CreateOrder 用户发布订单
func CreateOrder(c *gin.Context) {
	claims := service.GetClaims(c)

	var req model.CreateOrderReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "参数错误"})
		return
	}

	order, err := service.CreateOrder(claims.UserID, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "创建订单失败"})
		return
	}

	c.JSON(http.StatusOK, order)
}

// ListOrders 订单列表（按角色返回不同数据）
func ListOrders(c *gin.Context) {
	claims := service.GetClaims(c)

	var orders []model.Order
	var err error

	// 根据查询参数决定返回类型
	listType := c.Query("type") // my(我的) | hall(接单大厅) | jobs(已接单)

	switch listType {
	case "hall":
		if claims.Role != "worker" {
			c.JSON(http.StatusForbidden, gin.H{"error": "仅师傅可查看接单大厅"})
			return
		}
		// 读取用户位置，用于距离计算
		lat := parseFloatParam(c.Query("lat"))
		lng := parseFloatParam(c.Query("lng"))
		orders, err = repository.ListPendingOrdersByDistance(lat, lng)
	case "jobs":
		if claims.Role != "worker" {
			c.JSON(http.StatusForbidden, gin.H{"error": "仅师傅可查看已接订单"})
			return
		}
		orders, err = repository.ListOrdersByWorker(claims.UserID)
	default: // "my"
		orders, err = repository.ListOrdersByCustomer(claims.UserID)
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询失败"})
		return
	}
	if orders == nil {
		orders = []model.Order{}
	}

	c.JSON(http.StatusOK, orders)
}

func parseFloatParam(s string) float64 {
	if s == "" {
		return 0
	}
	var f float64
	fmt.Sscanf(s, "%f", &f)
	return f
}

// GetOrder 订单详情
func GetOrder(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "参数错误"})
		return
	}

	order, err := repository.GetOrderByID(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "订单不存在"})
		return
	}

	c.JSON(http.StatusOK, order)
}

// AcceptOrder 师傅接单
func AcceptOrder(c *gin.Context) {
	claims := service.GetClaims(c)
	if claims.Role != "worker" {
		c.JSON(http.StatusForbidden, gin.H{"error": "仅师傅可接单"})
		return
	}

	idStr := c.Param("id")
	orderID, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "参数错误"})
		return
	}

	if err := service.AcceptOrder(claims.UserID, orderID); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "接单成功"})
}

// ArriveOrder 师傅确认到达
func ArriveOrder(c *gin.Context) {
	claims := service.GetClaims(c)

	idStr := c.Param("id")
	orderID, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "参数错误"})
		return
	}

	if err := service.ArriveOrder(claims.UserID, orderID); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "已确认到达"})
}

// CompleteOrder 确认完成
func CompleteOrder(c *gin.Context) {
	claims := service.GetClaims(c)

	idStr := c.Param("id")
	orderID, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "参数错误"})
		return
	}

	if err := service.CompleteOrder(claims.UserID, orderID); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "订单已完成"})
}

// CancelOrder 取消订单
func CancelOrder(c *gin.Context) {
	claims := service.GetClaims(c)

	idStr := c.Param("id")
	orderID, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "参数错误"})
		return
	}

	var req struct {
		Reason string `json:"reason"`
	}
	c.ShouldBindJSON(&req)

	if err := service.CancelOrder(claims.UserID, orderID, req.Reason); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "订单已取消"})
}
