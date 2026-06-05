package repository

import (
	"fmt"
	"math"
	"sort"
	"time"

	"repair_server/internal/model"
)

// CreateOrder 创建订单
func CreateOrder(o *model.Order) error {
	o.OrderNo = fmt.Sprintf("%s%04d", time.Now().Format("20060102"), time.Now().UnixNano()%10000)
	result, err := DB.Exec(
		`INSERT INTO orders (order_no, customer_id, category_id, description, images, address, lat, lng, status, price)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		o.OrderNo, o.CustomerID, o.CategoryID, o.Description, o.Images, o.Address, o.Lat, o.Lng, "pending", o.Price,
	)
	if err != nil {
		return err
	}
	o.ID, _ = result.LastInsertId()
	o.Status = model.OrderStatusPending
	o.CreatedAt = time.Now()
	return nil
}

// GetOrderByID 获取订单详情
func GetOrderByID(id int64) (*model.Order, error) {
	o := &model.Order{}
	err := DB.QueryRow(
		`SELECT o.id, o.order_no, o.customer_id, o.worker_id, o.category_id,
		        o.description, o.images, o.address, o.lat, o.lng, o.status, o.price,
		        o.cancel_reason, o.created_at, o.accepted_at, o.arrived_at, o.completed_at
		 FROM orders o WHERE o.id=?`, id,
	).Scan(&o.ID, &o.OrderNo, &o.CustomerID, &o.WorkerID, &o.CategoryID,
		&o.Description, &o.Images, &o.Address, &o.Lat, &o.Lng, &o.Status, &o.Price,
		&o.CancelReason, &o.CreatedAt, &o.AcceptedAt, &o.ArrivedAt, &o.CompletedAt)
	if err != nil {
		return nil, err
	}
	return o, nil
}

// ListOrdersByCustomer 用户查看自己的订单
func ListOrdersByCustomer(customerID int64) ([]model.Order, error) {
	return queryOrders("WHERE o.customer_id = ? ORDER BY o.created_at DESC", customerID)
}

// ListPendingOrders 师傅端：查看待接订单
func ListPendingOrders() ([]model.Order, error) {
	return queryOrders("WHERE o.status = 'pending' ORDER BY o.created_at DESC")
}

// ListPendingOrdersByDistance 师傅端：查看待接订单（按距离排序）
func ListPendingOrdersByDistance(lat, lng float64) ([]model.Order, error) {
	orders, err := queryOrders("WHERE o.status = 'pending' ORDER BY o.created_at DESC")
	if err != nil {
		return nil, err
	}

	// 计算距离
	if lat != 0 && lng != 0 {
		for i := range orders {
			orders[i].Distance = haversine(lat, lng, orders[i].Lat, orders[i].Lng)
		}
		// 按距离升序
		sort.Slice(orders, func(i, j int) bool {
			return orders[i].Distance < orders[j].Distance
		})
	}
	return orders, nil
}

// haversine 计算两点间距离（km）
func haversine(lat1, lng1, lat2, lng2 float64) float64 {
	if lat2 == 0 && lng2 == 0 {
		return 9999 // 无位置信息的订单排最后
	}
	const R = 6371.0
	dLat := (lat2 - lat1) * (3.14159265 / 180)
	dLng := (lng2 - lng1) * (3.14159265 / 180)
	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1*(3.14159265/180))*math.Cos(lat2*(3.14159265/180))*
			math.Sin(dLng/2)*math.Sin(dLng/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
	return math.Round(R*c*10) / 10 // 保留 1 位小数
}

// ListOrdersByWorker 师傅查看已接订单
func ListOrdersByWorker(workerID int64) ([]model.Order, error) {
	return queryOrders("WHERE o.worker_id = ? ORDER BY o.created_at DESC", workerID)
}

func queryOrders(where string, args ...interface{}) ([]model.Order, error) {
	query := fmt.Sprintf(
		`SELECT o.id, o.order_no, o.customer_id, o.worker_id, o.category_id,
		        o.description, o.images, o.address, o.lat, o.lng, o.status, o.price,
		        o.cancel_reason, o.created_at, o.accepted_at, o.arrived_at, o.completed_at,
		        COALESCE(cu.name, '') as customer_name,
		        COALESCE(wu.name, '') as worker_name,
		        COALESCE(sc.name, '') as category_name
		 FROM orders o
		 LEFT JOIN users cu ON o.customer_id = cu.id
		 LEFT JOIN users wu ON o.worker_id = wu.id
		 LEFT JOIN service_categories sc ON o.category_id = sc.id
		 %s`, where)

	rows, err := DB.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var orders []model.Order
	for rows.Next() {
		var o model.Order
		if err := rows.Scan(&o.ID, &o.OrderNo, &o.CustomerID, &o.WorkerID, &o.CategoryID,
			&o.Description, &o.Images, &o.Address, &o.Lat, &o.Lng, &o.Status, &o.Price,
			&o.CancelReason, &o.CreatedAt, &o.AcceptedAt, &o.ArrivedAt, &o.CompletedAt,
			&o.CustomerName, &o.WorkerName, &o.CategoryName); err != nil {
			return nil, err
		}
		orders = append(orders, o)
	}
	return orders, nil
}

// WorkerStats 师傅收入统计
type WorkerStats struct {
	TotalOrders    int   `json:"total_orders"`
	TotalEarnings  int64 `json:"total_earnings"`
	MonthOrders    int   `json:"month_orders"`
	MonthEarnings  int64 `json:"month_earnings"`
	PendingOrders  int   `json:"pending_orders"`
	OngoingOrders  int   `json:"ongoing_orders"`
}

// GetWorkerStats 获取师傅收入统计
func GetWorkerStats(workerID int64) (*WorkerStats, error) {
	s := &WorkerStats{}

	// 已完成订单总数和总收入
	DB.QueryRow(
		"SELECT COUNT(*), COALESCE(SUM(price), 0) FROM orders WHERE worker_id=? AND status='completed'",
		workerID,
	).Scan(&s.TotalOrders, &s.TotalEarnings)

	// 本月已完成订单和收入
	DB.QueryRow(
		`SELECT COUNT(*), COALESCE(SUM(price), 0) FROM orders
		 WHERE worker_id=? AND status='completed'
		 AND strftime('%Y-%m', created_at) = strftime('%Y-%m', 'now')`,
		workerID,
	).Scan(&s.MonthOrders, &s.MonthEarnings)

	// 待接单数（hall中pending的）
	DB.QueryRow(
		"SELECT COUNT(*) FROM orders WHERE status='pending'",
	).Scan(&s.PendingOrders)

	// 进行中的订单
	DB.QueryRow(
		"SELECT COUNT(*) FROM orders WHERE worker_id=? AND status='ongoing'",
		workerID,
	).Scan(&s.OngoingOrders)

	return s, nil
}

// UpdateOrderStatus 更新订单状态
func UpdateOrderStatus(id int64, status string, extra map[string]interface{}) error {
	query := "UPDATE orders SET status=? "
	args := []interface{}{status}

	if status == model.OrderStatusAccepted {
		query += ", worker_id=?, accepted_at=CURRENT_TIMESTAMP"
		args = append(args, extra["worker_id"])
	}
	if status == model.OrderStatusOngoing {
		query += ", arrived_at=CURRENT_TIMESTAMP"
	}
	if status == model.OrderStatusCompleted {
		query += ", completed_at=CURRENT_TIMESTAMP"
	}
	if status == model.OrderStatusCancelled {
		query += ", cancel_reason=?"
		args = append(args, extra["cancel_reason"])
	}

	query += " WHERE id=?"
	args = append(args, id)

	_, err := DB.Exec(query, args...)
	return err
}
