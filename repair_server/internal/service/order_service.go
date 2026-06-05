package service

import (
	"errors"

	"repair_server/internal/model"
	"repair_server/internal/repository"
)

// CreateOrder 用户发布订单
func CreateOrder(customerID int64, req *model.CreateOrderReq) (*model.Order, error) {
	order := &model.Order{
		CustomerID:  customerID,
		CategoryID:  req.CategoryID,
		Description: req.Description,
		Images:      req.Images,
		Address:     req.Address,
		Lat:         req.Lat,
		Lng:         req.Lng,
	}
	if order.Images == "" {
		order.Images = "[]"
	}
	if err := repository.CreateOrder(order); err != nil {
		return nil, err
	}
	return order, nil
}

// AcceptOrder 师傅接单
func AcceptOrder(workerID, orderID int64) error {
	order, err := repository.GetOrderByID(orderID)
	if err != nil {
		return errors.New("订单不存在")
	}
	if order.Status != model.OrderStatusPending {
		return errors.New("订单已被接或已取消")
	}
	return repository.UpdateOrderStatus(orderID, model.OrderStatusAccepted, map[string]interface{}{
		"worker_id": workerID,
	})
}

// ArriveOrder 师傅确认到达
func ArriveOrder(workerID, orderID int64) error {
	order, err := repository.GetOrderByID(orderID)
	if err != nil {
		return errors.New("订单不存在")
	}
	if order.WorkerID == nil || *order.WorkerID != workerID {
		return errors.New("无权操作此订单")
	}
	if order.Status != model.OrderStatusAccepted {
		return errors.New("订单状态不允许此操作")
	}
	return repository.UpdateOrderStatus(orderID, model.OrderStatusOngoing, nil)
}

// CompleteOrder 确认完成（用户或师傅都可以）
func CompleteOrder(userID, orderID int64) error {
	order, err := repository.GetOrderByID(orderID)
	if err != nil {
		return errors.New("订单不存在")
	}
	if order.CustomerID != userID && (order.WorkerID == nil || *order.WorkerID != userID) {
		return errors.New("无权操作此订单")
	}
	if order.Status != model.OrderStatusOngoing {
		return errors.New("订单状态不允许此操作")
	}
	return repository.UpdateOrderStatus(orderID, model.OrderStatusCompleted, nil)
}

// CancelOrder 取消订单
func CancelOrder(userID, orderID int64, reason string) error {
	order, err := repository.GetOrderByID(orderID)
	if err != nil {
		return errors.New("订单不存在")
	}
	if order.CustomerID != userID && (order.WorkerID == nil || *order.WorkerID != userID) {
		return errors.New("无权操作此订单")
	}
	if order.Status == model.OrderStatusCompleted || order.Status == model.OrderStatusCancelled {
		return errors.New("订单已完成或已取消")
	}
	return repository.UpdateOrderStatus(orderID, model.OrderStatusCancelled, map[string]interface{}{
		"cancel_reason": reason,
	})
}
