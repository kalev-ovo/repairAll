package repository

import (
	"database/sql"
	"fmt"
	"log"
	"os"
	"path/filepath"

	_ "modernc.org/sqlite"
)

var DB *sql.DB

// InitDB 初始化数据库连接并执行迁移
func InitDB(dbPath string) error {
	dir := filepath.Dir(dbPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("create data dir: %w", err)
	}

	var err error
	DB, err = sql.Open("sqlite", dbPath)
	if err != nil {
		return fmt.Errorf("open db: %w", err)
	}

	DB.SetMaxOpenConns(1) // SQLite 写串行

	// 启用 WAL 模式、外键
	if _, err := DB.Exec("PRAGMA journal_mode=WAL"); err != nil {
		return fmt.Errorf("enable WAL: %w", err)
	}
	if _, err := DB.Exec("PRAGMA busy_timeout=5000"); err != nil {
		return fmt.Errorf("set busy_timeout: %w", err)
	}
	if _, err := DB.Exec("PRAGMA foreign_keys=ON"); err != nil {
		return fmt.Errorf("enable foreign_keys: %w", err)
	}

	if err := migrate(); err != nil {
		return fmt.Errorf("migrate: %w", err)
	}

	if err := seedCategories(); err != nil {
		log.Printf("seed categories warning: %v", err)
	}

	log.Println("Database initialized successfully")
	return nil
}

func migrate() error {
	schema := `
	CREATE TABLE IF NOT EXISTS users (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		phone TEXT UNIQUE NOT NULL,
		password_hash TEXT NOT NULL DEFAULT '',
		role TEXT NOT NULL CHECK(role IN ('customer','worker')),
		name TEXT DEFAULT '',
		avatar TEXT DEFAULT '',
		status TEXT DEFAULT 'active' CHECK(status IN ('active','banned')),
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);

	CREATE TABLE IF NOT EXISTS workers (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		user_id INTEGER UNIQUE REFERENCES users(id),
		real_name TEXT DEFAULT '',
		id_card TEXT DEFAULT '',
		skills TEXT DEFAULT '[]',
		years_exp INTEGER DEFAULT 0,
		cert_photos TEXT DEFAULT '[]',
		service_city TEXT DEFAULT '',
		lat REAL DEFAULT 0,
		lng REAL DEFAULT 0,
		service_radius INTEGER DEFAULT 10,
		bio TEXT DEFAULT '',
		is_verified INTEGER DEFAULT 0,
		balance INTEGER DEFAULT 0,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);

	CREATE TABLE IF NOT EXISTS service_categories (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		name TEXT NOT NULL,
		icon TEXT DEFAULT '',
		parent_id INTEGER REFERENCES service_categories(id),
		sort_order INTEGER DEFAULT 0,
		is_active INTEGER DEFAULT 1
	);

	CREATE TABLE IF NOT EXISTS orders (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		order_no TEXT UNIQUE NOT NULL,
		customer_id INTEGER NOT NULL REFERENCES users(id),
		worker_id INTEGER REFERENCES users(id),
		category_id INTEGER NOT NULL REFERENCES service_categories(id),
		description TEXT DEFAULT '',
		images TEXT DEFAULT '[]',
		address TEXT DEFAULT '',
		lat REAL DEFAULT 0,
		lng REAL DEFAULT 0,
		status TEXT DEFAULT 'pending' CHECK(status IN ('pending','accepted','ongoing','completed','cancelled')),
		price INTEGER DEFAULT 0,
		cancel_reason TEXT DEFAULT '',
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		accepted_at DATETIME,
		arrived_at DATETIME,
		completed_at DATETIME
	);

	CREATE TABLE IF NOT EXISTS reviews (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		order_id INTEGER NOT NULL REFERENCES orders(id),
		reviewer_id INTEGER NOT NULL REFERENCES users(id),
		target_id INTEGER NOT NULL REFERENCES users(id),
		rating INTEGER NOT NULL CHECK(rating >= 1 AND rating <= 5),
		content TEXT DEFAULT '',
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);

	CREATE TABLE IF NOT EXISTS messages (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		order_id INTEGER NOT NULL REFERENCES orders(id),
		sender_id INTEGER NOT NULL REFERENCES users(id),
		receiver_id INTEGER NOT NULL REFERENCES users(id),
		type TEXT DEFAULT 'text' CHECK(type IN ('text','image','system')),
		content TEXT DEFAULT '',
		is_read INTEGER DEFAULT 0,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);

	CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders(customer_id);
	CREATE INDEX IF NOT EXISTS idx_orders_worker ON orders(worker_id);
	CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
	CREATE INDEX IF NOT EXISTS idx_messages_order ON messages(order_id);
	CREATE INDEX IF NOT EXISTS idx_reviews_target ON reviews(target_id);
	`

	_, err := DB.Exec(schema)
	return err
}

func seedCategories() error {
	var count int
	if err := DB.QueryRow("SELECT COUNT(*) FROM service_categories").Scan(&count); err != nil {
		return err
	}
	if count > 0 {
		return nil // 已有数据
	}

	categories := []struct {
		Name     string
		Icon     string
		ParentID *int64
		Sort     int
	}{
		// 一级类目
		{"家电维修", "tv", nil, 1},
		{"家电清洗", "cleaning_services", nil, 2},
		{"水电维修", "plumbing", nil, 3},
		{"家居安装", "home_repair_service", nil, 4},
	}

	for i, cat := range categories {
		result, err := DB.Exec(
			"INSERT INTO service_categories (name, icon, parent_id, sort_order) VALUES (?, ?, ?, ?)",
			cat.Name, cat.Icon, cat.ParentID, cat.Sort,
		)
		if err != nil {
			return err
		}
		parentID, _ := result.LastInsertId()

		// 二级类目
		subs := getSubCategories(i, parentID)
		for _, sub := range subs {
			_, err := DB.Exec(
				"INSERT INTO service_categories (name, icon, parent_id, sort_order) VALUES (?, ?, ?, ?)",
				sub.Name, sub.Icon, sub.ParentID, sub.Sort,
			)
			if err != nil {
				return err
			}
		}
	}

	log.Println("Seed categories done")
	return nil
}

func getSubCategories(parentIdx int, parentID int64) []struct {
	Name     string
	Icon     string
	ParentID *int64
	Sort     int
} {
	switch parentIdx {
	case 0: // 家电维修
		return []struct {
			Name     string
			Icon     string
			ParentID *int64
			Sort     int
		}{
			{"电视维修", "tv", &parentID, 1},
			{"冰箱维修", "kitchen", &parentID, 2},
			{"洗衣机维修", "local_laundry_service", &parentID, 3},
			{"空调维修", "air", &parentID, 4},
			{"热水器维修", "water_heater", &parentID, 5},
			{"油烟机维修", "range_hood", &parentID, 6},
		}
	case 1: // 家电清洗
		return []struct {
			Name     string
			Icon     string
			ParentID *int64
			Sort     int
		}{
			{"空调清洗", "air", &parentID, 1},
			{"洗衣机清洗", "local_laundry_service", &parentID, 2},
			{"油烟机清洗", "range_hood", &parentID, 3},
			{"热水器清洗", "water_heater", &parentID, 4},
		}
	case 2: // 水电维修
		return []struct {
			Name     string
			Icon     string
			ParentID *int64
			Sort     int
		}{
			{"水管维修", "water_drop", &parentID, 1},
			{"电路维修", "electric_bolt", &parentID, 2},
			{"马桶维修", "bathroom", &parentID, 3},
			{"下水道疏通", "plumbing", &parentID, 4},
			{"水龙头维修", "faucet", &parentID, 5},
		}
	case 3: // 家居安装
		return []struct {
			Name     string
			Icon     string
			ParentID *int64
			Sort     int
		}{
			{"灯具安装", "light", &parentID, 1},
			{"家具组装", "chair", &parentID, 2},
			{"墙面打孔", "build", &parentID, 3},
			{"窗帘安装", "blinds", &parentID, 4},
			{"卫浴安装", "bathroom", &parentID, 5},
		}
	}
	return nil
}
