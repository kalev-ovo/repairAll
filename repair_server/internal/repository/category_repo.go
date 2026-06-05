package repository

import "repair_server/internal/model"

// GetCategories 获取所有活跃类目
func GetCategories() ([]model.ServiceCategory, error) {
	rows, err := DB.Query(
		"SELECT id, name, icon, parent_id, sort_order, is_active FROM service_categories WHERE is_active=1 ORDER BY sort_order",
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var cats []model.ServiceCategory
	for rows.Next() {
		var c model.ServiceCategory
		if err := rows.Scan(&c.ID, &c.Name, &c.Icon, &c.ParentID, &c.SortOrder, &c.IsActive); err != nil {
			return nil, err
		}
		cats = append(cats, c)
	}
	return cats, nil
}
