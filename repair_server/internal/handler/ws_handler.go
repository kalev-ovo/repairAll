package handler

import (
	"encoding/json"
	"log"
	"net/http"
	"strconv"
	"sync"
	"time"

	"repair_server/internal/model"
	"repair_server/internal/repository"
	"repair_server/internal/service"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
}

// 连接管理
type wsClient struct {
	conn   *websocket.Conn
	userID int64
	send   chan []byte
}

var (
	clients   = sync.Map{} // userID -> *wsClient
)

// HandleChat WebSocket 聊天入口
func HandleChat(c *gin.Context) {
	token := c.Query("token")
	if token == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "缺少token"})
		return
	}

	claims, err := service.ParseToken(token)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "token无效"})
		return
	}

	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("ws upgrade error: %v", err)
		return
	}

	client := &wsClient{
		conn:   conn,
		userID: claims.UserID,
		send:   make(chan []byte, 32),
	}

	clients.Store(claims.UserID, client)
	defer func() {
		clients.Delete(claims.UserID)
		conn.Close()
	}()

	go writePump(client)
	readPump(client)
}

func readPump(c *wsClient) {
	defer close(c.send)

	for {
		_, msgBytes, err := c.conn.ReadMessage()
		if err != nil {
			break
		}

		var msg model.WSMessage
		if err := json.Unmarshal(msgBytes, &msg); err != nil {
			continue
		}

		msg.SenderID = c.userID
		msg.CreatedAt = time.Now().Format("2006-01-02 15:04:05")

		// 保存到数据库
		dbMsg := &model.Message{
			OrderID:    msg.OrderID,
			SenderID:   c.userID,
			ReceiverID: getReceiverID(msg.OrderID, c.userID),
			Type:       msg.Type,
			Content:    msg.Content,
		}
		if err := repository.SaveMessage(dbMsg); err != nil {
			log.Printf("save message error: %v", err)
		}

		// 推送给接收方
		reply, _ := json.Marshal(msg)
		if target, ok := clients.Load(dbMsg.ReceiverID); ok {
			target.(*wsClient).send <- reply
		}
		// 也回显给自己
		c.send <- reply
	}
}

func writePump(c *wsClient) {
	for msg := range c.send {
		if err := c.conn.WriteMessage(websocket.TextMessage, msg); err != nil {
			break
		}
	}
}

// getReceiverID 获取消息接收方ID
func getReceiverID(orderID, senderID int64) int64 {
	order, err := repository.GetOrderByID(orderID)
	if err != nil {
		return 0
	}
	if order.CustomerID == senderID {
		if order.WorkerID != nil {
			return *order.WorkerID
		}
		return 0
	}
	return order.CustomerID
}

// GetChatHistory 获取聊天记录
func GetChatHistory(c *gin.Context) {
	claims := service.GetClaims(c)

	orderIDStr := c.Query("order_id")
	orderID, err := strconv.ParseInt(orderIDStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "参数错误"})
		return
	}

	// 验证用户属于此订单
	order, err := repository.GetOrderByID(orderID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "订单不存在"})
		return
	}
	if order.CustomerID != claims.UserID && (order.WorkerID == nil || *order.WorkerID != claims.UserID) {
		c.JSON(http.StatusForbidden, gin.H{"error": "无权访问"})
		return
	}

	msgs, err := repository.GetMessagesByOrder(orderID, 100)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询失败"})
		return
	}
	if msgs == nil {
		msgs = []model.Message{}
	}

	// 标记已读
	_ = repository.MarkMessagesRead(orderID, claims.UserID)

	c.JSON(http.StatusOK, msgs)
}
