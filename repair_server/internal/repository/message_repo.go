package repository

import (
	"time"

	"repair_server/internal/model"
)

// SaveMessage 保存聊天消息
func SaveMessage(m *model.Message) error {
	result, err := DB.Exec(
		"INSERT INTO messages (order_id, sender_id, receiver_id, type, content) VALUES (?, ?, ?, ?, ?)",
		m.OrderID, m.SenderID, m.ReceiverID, m.Type, m.Content,
	)
	if err != nil {
		return err
	}
	m.ID, _ = result.LastInsertId()
	m.CreatedAt = time.Now()
	return nil
}

// GetMessagesByOrder 获取订单聊天记录
func GetMessagesByOrder(orderID int64, limit int) ([]model.Message, error) {
	rows, err := DB.Query(
		`SELECT id, order_id, sender_id, receiver_id, type, content, is_read, created_at
		 FROM messages WHERE order_id=? ORDER BY created_at DESC LIMIT ?`,
		orderID, limit,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var msgs []model.Message
	for rows.Next() {
		var m model.Message
		if err := rows.Scan(&m.ID, &m.OrderID, &m.SenderID, &m.ReceiverID, &m.Type, &m.Content, &m.IsRead, &m.CreatedAt); err != nil {
			return nil, err
		}
		msgs = append(msgs, m)
	}
	// 反转顺序为时间正序
	for i, j := 0, len(msgs)-1; i < j; i, j = i+1, j-1 {
		msgs[i], msgs[j] = msgs[j], msgs[i]
	}
	return msgs, nil
}

// MarkMessagesRead 标记消息已读
func MarkMessagesRead(orderID, receiverID int64) error {
	_, err := DB.Exec("UPDATE messages SET is_read=1 WHERE order_id=? AND receiver_id=? AND is_read=0",
		orderID, receiverID)
	return err
}
