package repository

import (
	"time"

	"repair_server/internal/model"
)

// CreateReview 创建评价
func CreateReview(r *model.Review) error {
	result, err := DB.Exec(
		"INSERT INTO reviews (order_id, reviewer_id, target_id, rating, content) VALUES (?, ?, ?, ?, ?)",
		r.OrderID, r.ReviewerID, r.TargetID, r.Rating, r.Content,
	)
	if err != nil {
		return err
	}
	r.ID, _ = result.LastInsertId()
	r.CreatedAt = time.Now()
	return nil
}

// GetReviewsByUser 查看某人收到的评价
func GetReviewsByUser(userID int64) ([]model.Review, error) {
	rows, err := DB.Query(
		"SELECT id, order_id, reviewer_id, target_id, rating, content, created_at FROM reviews WHERE target_id=? ORDER BY created_at DESC",
		userID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var reviews []model.Review
	for rows.Next() {
		var r model.Review
		if err := rows.Scan(&r.ID, &r.OrderID, &r.ReviewerID, &r.TargetID, &r.Rating, &r.Content, &r.CreatedAt); err != nil {
			return nil, err
		}
		reviews = append(reviews, r)
	}
	return reviews, nil
}
