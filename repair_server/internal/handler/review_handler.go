package handler

import (
	"net/http"
	"strconv"

	"repair_server/internal/model"
	"repair_server/internal/repository"
	"repair_server/internal/service"

	"github.com/gin-gonic/gin"
)

// CreateReview 提交评价
func CreateReview(c *gin.Context) {
	claims := service.GetClaims(c)

	var req model.CreateReviewReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "参数错误"})
		return
	}

	// 验证订单存在且已完成
	order, err := repository.GetOrderByID(req.OrderID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "订单不存在"})
		return
	}
	if order.Status != model.OrderStatusCompleted {
		c.JSON(http.StatusBadRequest, gin.H{"error": "订单未完成，无法评价"})
		return
	}

	// 确定评价对象
	var targetID int64
	if claims.UserID == order.CustomerID {
		if order.WorkerID == nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "订单无师傅"})
			return
		}
		targetID = *order.WorkerID
	} else if order.WorkerID != nil && claims.UserID == *order.WorkerID {
		targetID = order.CustomerID
	} else {
		c.JSON(http.StatusForbidden, gin.H{"error": "无权评价"})
		return
	}

	review := &model.Review{
		OrderID:    req.OrderID,
		ReviewerID: claims.UserID,
		TargetID:   targetID,
		Rating:     req.Rating,
		Content:    req.Content,
	}

	if err := repository.CreateReview(review); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "评价失败"})
		return
	}

	c.JSON(http.StatusOK, review)
}

// GetUserReviews 查看用户评价
func GetUserReviews(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.ParseInt(idStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "参数错误"})
		return
	}

	reviews, err := repository.GetReviewsByUser(id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询失败"})
		return
	}
	if reviews == nil {
		reviews = []model.Review{}
	}

	c.JSON(http.StatusOK, reviews)
}
