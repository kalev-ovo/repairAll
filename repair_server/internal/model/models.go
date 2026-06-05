package model

import "time"

// User 用户（同时支持 customer 和 worker 角色）
type User struct {
	ID           int64     `json:"id"`
	Phone        string    `json:"phone"`
	PasswordHash string    `json:"-"`
	Role         string    `json:"role"` // "customer" | "worker"
	Name         string    `json:"name"`
	Avatar       string    `json:"avatar"`
	Status       string    `json:"status"` // active | banned
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// Worker 师傅资料
type Worker struct {
	ID            int64     `json:"id"`
	UserID        int64     `json:"user_id"`
	RealName      string    `json:"real_name"`
	IDCard        string    `json:"-"`
	Skills        string    `json:"skills"`        // JSON array
	YearsExp      int       `json:"years_exp"`
	CertPhotos    string    `json:"cert_photos"`   // JSON array
	ServiceCity   string    `json:"service_city"`
	Lat           float64   `json:"lat"`
	Lng           float64   `json:"lng"`
	ServiceRadius int       `json:"service_radius"` // km
	Bio           string    `json:"bio"`
	IsVerified    bool      `json:"is_verified"`
	VerifyStatus  string    `json:"verify_status"` // none/pending/verified/rejected
	VerifyNote    string    `json:"verify_note"`
	Balance       int64     `json:"balance"` // 分
	CreatedAt     time.Time `json:"created_at"`
}

// ServiceCategory 服务类目
type ServiceCategory struct {
	ID       int64  `json:"id"`
	Name     string `json:"name"`
	Icon     string `json:"icon"`
	ParentID *int64 `json:"parent_id"`
	SortOrder int   `json:"sort_order"`
	IsActive bool   `json:"is_active"`
}

// Order 订单
type Order struct {
	ID           int64      `json:"id"`
	OrderNo      string     `json:"order_no"`
	CustomerID   int64      `json:"customer_id"`
	WorkerID     *int64     `json:"worker_id"`
	CategoryID   int64      `json:"category_id"`
	Description  string     `json:"description"`
	Images       string     `json:"images"`       // JSON array
	Address      string     `json:"address"`
	Lat          float64    `json:"lat"`
	Lng          float64    `json:"lng"`
	Status       string     `json:"status"`       // pending/accepted/ongoing/completed/cancelled
	Price        int64      `json:"price"`         // 分
	CancelReason string     `json:"cancel_reason"`
	CreatedAt    time.Time  `json:"created_at"`
	AcceptedAt   *time.Time `json:"accepted_at"`
	ArrivedAt    *time.Time `json:"arrived_at"`
	CompletedAt  *time.Time `json:"completed_at"`

	// 关联字段（查询时填充）
	CustomerName string  `json:"customer_name,omitempty"`
	WorkerName   string  `json:"worker_name,omitempty"`
	CategoryName string  `json:"category_name,omitempty"`
	Distance     float64 `json:"distance,omitempty"` // km，查询时计算
}

// Review 评价
type Review struct {
	ID         int64     `json:"id"`
	OrderID    int64     `json:"order_id"`
	ReviewerID int64     `json:"reviewer_id"`
	TargetID   int64     `json:"target_id"`
	Rating     int       `json:"rating"` // 1-5
	Content    string    `json:"content"`
	CreatedAt  time.Time `json:"created_at"`
}

// Message 聊天消息
type Message struct {
	ID         int64     `json:"id"`
	OrderID    int64     `json:"order_id"`
	SenderID   int64     `json:"sender_id"`
	ReceiverID int64     `json:"receiver_id"`
	Type       string    `json:"type"` // text | image | system
	Content    string    `json:"content"`
	IsRead     bool      `json:"is_read"`
	CreatedAt  time.Time `json:"created_at"`
}

// --- 请求/响应 DTO ---

type SendCodeReq struct {
	Phone string `json:"phone" binding:"required"`
}

type LoginReq struct {
	Phone string `json:"phone" binding:"required"`
	Code  string `json:"code" binding:"required"`
}

type RegisterReq struct {
	Phone string `json:"phone" binding:"required"`
	Code  string `json:"code" binding:"required"`
	Role  string `json:"role" binding:"required,oneof=customer worker"`
}

type AuthResp struct {
	Token string `json:"token"`
	User  User   `json:"user"`
}

type CreateOrderReq struct {
	CategoryID  int64   `json:"category_id" binding:"required"`
	Description string  `json:"description" binding:"required"`
	Images      string  `json:"images"`
	Address     string  `json:"address" binding:"required"`
	Lat         float64 `json:"lat"`
	Lng         float64 `json:"lng"`
	Price       int64   `json:"price"` // 预算价格（分），可选
}

type UpdateProfileReq struct {
	Name   string `json:"name"`
	Avatar string `json:"avatar"`
}

type WorkerProfileReq struct {
	RealName      string  `json:"real_name"`
	IDCard        string  `json:"id_card"`
	Skills        string  `json:"skills"`
	YearsExp      int     `json:"years_exp"`
	ServiceCity   string  `json:"service_city"`
	Lat           float64 `json:"lat"`
	Lng           float64 `json:"lng"`
	ServiceRadius int     `json:"service_radius"`
	Bio           string  `json:"bio"`
}

type CreateReviewReq struct {
	OrderID int64  `json:"order_id" binding:"required"`
	Rating  int    `json:"rating" binding:"required,min=1,max=5"`
	Content string `json:"content"`
}

// WebSocket 消息
type WSMessage struct {
	Type      string `json:"type"`    // text | image | system
	Content   string `json:"content"`
	OrderID   int64  `json:"order_id"`
	SenderID  int64  `json:"sender_id,omitempty"`
	CreatedAt string `json:"created_at,omitempty"`
}

// 常量：订单状态
const (
	OrderStatusPending   = "pending"
	OrderStatusAccepted  = "accepted"
	OrderStatusOngoing   = "ongoing"
	OrderStatusCompleted = "completed"
	OrderStatusCancelled = "cancelled"
)

// ValidOrderTransitions 状态转移规则
var ValidOrderTransitions = map[string][]string{
	OrderStatusPending:   {OrderStatusAccepted, OrderStatusCancelled},
	OrderStatusAccepted:  {OrderStatusOngoing, OrderStatusCancelled},
	OrderStatusOngoing:   {OrderStatusCompleted, OrderStatusCancelled},
	OrderStatusCompleted: {}, // 不可再变更（评价是独立操作）
	OrderStatusCancelled: {},
}
