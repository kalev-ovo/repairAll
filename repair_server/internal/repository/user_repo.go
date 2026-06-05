package repository

import (
	"repair_server/internal/model"
)

// ========== User ==========

func CreateUser(user *model.User) error {
	result, err := DB.Exec(
		"INSERT INTO users (phone, password_hash, role, name) VALUES (?, ?, ?, ?)",
		user.Phone, user.PasswordHash, user.Role, user.Name,
	)
	if err != nil {
		return err
	}
	user.ID, _ = result.LastInsertId()
	return nil
}

func GetUserByPhone(phone string) (*model.User, error) {
	u := &model.User{}
	err := DB.QueryRow(
		"SELECT id, phone, password_hash, role, name, avatar, status, created_at, updated_at FROM users WHERE phone=?",
		phone,
	).Scan(&u.ID, &u.Phone, &u.PasswordHash, &u.Role, &u.Name, &u.Avatar, &u.Status, &u.CreatedAt, &u.UpdatedAt)
	if err != nil {
		return nil, err
	}
	return u, nil
}

func GetUserByID(id int64) (*model.User, error) {
	u := &model.User{}
	err := DB.QueryRow(
		"SELECT id, phone, password_hash, role, name, avatar, status, created_at, updated_at FROM users WHERE id=?",
		id,
	).Scan(&u.ID, &u.Phone, &u.PasswordHash, &u.Role, &u.Name, &u.Avatar, &u.Status, &u.CreatedAt, &u.UpdatedAt)
	if err != nil {
		return nil, err
	}
	return u, nil
}

func UpdateUser(id int64, name, avatar string) error {
	_, err := DB.Exec("UPDATE users SET name=?, avatar=?, updated_at=CURRENT_TIMESTAMP WHERE id=?", name, avatar, id)
	return err
}

func SwitchUserRole(id int64, role string) error {
	_, err := DB.Exec("UPDATE users SET role=?, updated_at=CURRENT_TIMESTAMP WHERE id=?", role, id)
	return err
}

// ========== Worker ==========

func CreateWorker(w *model.Worker) error {
	result, err := DB.Exec(
		`INSERT INTO workers (user_id, real_name, id_card, skills, years_exp, service_city, lat, lng, service_radius, bio)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		w.UserID, w.RealName, w.IDCard, w.Skills, w.YearsExp, w.ServiceCity, w.Lat, w.Lng, w.ServiceRadius, w.Bio,
	)
	if err != nil {
		return err
	}
	w.ID, _ = result.LastInsertId()
	return nil
}

func GetWorkerByUserID(userID int64) (*model.Worker, error) {
	w := &model.Worker{}
	err := DB.QueryRow(
		`SELECT id, user_id, real_name, id_card, skills, years_exp, cert_photos,
		        service_city, lat, lng, service_radius, bio, is_verified, balance, created_at
		 FROM workers WHERE user_id=?`, userID,
	).Scan(&w.ID, &w.UserID, &w.RealName, &w.IDCard, &w.Skills, &w.YearsExp, &w.CertPhotos,
		&w.ServiceCity, &w.Lat, &w.Lng, &w.ServiceRadius, &w.Bio, &w.IsVerified, &w.Balance, &w.CreatedAt)
	if err != nil {
		return nil, err
	}
	return w, nil
}

func UpdateWorker(userID int64, w *model.Worker) error {
	_, err := DB.Exec(
		`UPDATE workers SET real_name=?, id_card=?, skills=?, years_exp=?,
		 service_city=?, lat=?, lng=?, service_radius=?, bio=? WHERE user_id=?`,
		w.RealName, w.IDCard, w.Skills, w.YearsExp, w.ServiceCity, w.Lat, w.Lng, w.ServiceRadius, w.Bio, userID,
	)
	return err
}

func ListVerifiedWorkers() ([]model.Worker, error) {
	rows, err := DB.Query(
		`SELECT w.id, w.user_id, w.real_name, w.skills, w.years_exp,
		        w.service_city, w.lat, w.lng, w.service_radius, w.bio, w.is_verified, w.balance, w.created_at,
		        u.name, u.avatar
		 FROM workers w JOIN users u ON w.user_id = u.id
		 WHERE w.is_verified=1 AND u.status='active'`,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var workers []model.Worker
	for rows.Next() {
		var w model.Worker
		if err := rows.Scan(&w.ID, &w.UserID, &w.RealName, &w.Skills, &w.YearsExp,
			&w.ServiceCity, &w.Lat, &w.Lng, &w.ServiceRadius, &w.Bio, &w.IsVerified, &w.Balance, &w.CreatedAt,
			new(string), new(string)); err != nil {
			return nil, err
		}
		workers = append(workers, w)
	}
	return workers, nil
}
