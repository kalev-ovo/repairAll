package admin

import (
	"fmt"
	"log"
	"os"
	"strconv"
	"text/tabwriter"

	"repair_server/internal/model"
	"repair_server/internal/repository"
)

// Run CLI 管理入口
func Run(args []string) {
	if len(args) < 1 {
		printAdminUsage()
		return
	}

	// 初始化数据库
	dbPath := os.Getenv("REPAIR_DB")
	if dbPath == "" {
		dbPath = "./data/repair.db"
	}
	if err := repository.InitDB(dbPath); err != nil {
		log.Fatalf("database init failed: %v", err)
	}

	resource := args[0]

	// 无子命令的独立操作
	if resource == "stats" {
		adminStats()
		return
	}

	if len(args) < 2 {
		printAdminUsage()
		return
	}
	action := args[1]

	switch resource {
	case "category":
		adminCategory(action, args[2:])
	case "user":
		adminUser(action, args[2:])
	case "worker":
		adminWorker(action, args[2:])
	case "order":
		adminOrder(action, args[2:])
	default:
		printAdminUsage()
	}
}

func adminCategory(action string, args []string) {
	switch action {
	case "list":
		cats, _ := repository.GetCategories()
		w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
		fmt.Fprintln(w, "ID\tName\tParentID\tSort")
		for _, c := range cats {
			pid := "-"
			if c.ParentID != nil {
				pid = fmt.Sprintf("%d", *c.ParentID)
			}
			fmt.Fprintf(w, "%d\t%s\t%s\t%d\n", c.ID, c.Name, pid, c.SortOrder)
		}
		w.Flush()
	case "add":
		if len(args) < 1 {
			fmt.Println("Usage: repair admin category add <name>")
			return
		}
		_, err := repository.DB.Exec(
			"INSERT INTO service_categories (name) VALUES (?)", args[0],
		)
		if err != nil {
			fmt.Printf("Add failed: %v\n", err)
		} else {
			fmt.Printf("Category '%s' added\n", args[0])
		}
	default:
		fmt.Printf("Unknown action: %s\n", action)
	}
}

func adminUser(action string, args []string) {
	switch action {
	case "list":
		rows, err := repository.DB.Query(
			"SELECT id, phone, role, name, status, created_at FROM users ORDER BY id DESC LIMIT 50",
		)
		if err != nil {
			fmt.Printf("Query failed: %v\n", err)
			return
		}
		defer rows.Close()

		w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
		fmt.Fprintln(w, "ID\tPhone\tRole\tName\tStatus\tCreated")
		for rows.Next() {
			var u model.User
			rows.Scan(&u.ID, &u.Phone, &u.Role, &u.Name, &u.Status, &u.CreatedAt)
			fmt.Fprintf(w, "%d\t%s\t%s\t%s\t%s\t%s\n",
				u.ID, u.Phone, u.Role, u.Name, u.Status, u.CreatedAt.Format("01-02 15:04"))
		}
		w.Flush()
	case "detail":
		if len(args) < 1 {
			fmt.Println("Usage: repair admin user detail <id>")
			return
		}
		id, _ := strconv.ParseInt(args[0], 10, 64)
		u, err := repository.GetUserByID(id)
		if err != nil {
			fmt.Printf("User not found: %v\n", err)
			return
		}
		fmt.Printf("ID: %d\nPhone: %s\nRole: %s\nName: %s\nStatus: %s\nCreated: %s\n",
			u.ID, u.Phone, u.Role, u.Name, u.Status, u.CreatedAt.Format("2006-01-02 15:04"))
	default:
		fmt.Printf("Unknown action: %s\n", action)
	}
}

func adminWorker(action string, args []string) {
	switch action {
	case "verify":
		if len(args) < 1 {
			fmt.Println("Usage: repair admin worker verify <user_id>")
			return
		}
		id, _ := strconv.ParseInt(args[0], 10, 64)
		_, err := repository.DB.Exec("UPDATE workers SET is_verified=1 WHERE user_id=?", id)
		if err != nil {
			fmt.Printf("Verify failed: %v\n", err)
		} else {
			fmt.Printf("Worker user_id=%d verified\n", id)
		}
	default:
		fmt.Printf("Unknown action: %s\n", action)
	}
}

func adminOrder(action string, args []string) {
	switch action {
	case "list":
		rows, err := repository.DB.Query(
			`SELECT o.id, o.order_no, cu.name, wu.name, sc.name, o.status, o.created_at
			 FROM orders o
			 LEFT JOIN users cu ON o.customer_id = cu.id
			 LEFT JOIN users wu ON o.worker_id = wu.id
			 LEFT JOIN service_categories sc ON o.category_id = sc.id
			 ORDER BY o.id DESC LIMIT 50`,
		)
		if err != nil {
			fmt.Printf("Query failed: %v\n", err)
			return
		}
		defer rows.Close()

		w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
		fmt.Fprintln(w, "ID\tOrderNo\tCustomer\tWorker\tService\tStatus\tCreated")
		for rows.Next() {
			var id int64
			var orderNo, customerName, categoryName, status, createdAt string
			var workerName *string
			rows.Scan(&id, &orderNo, &customerName, &workerName, &categoryName, &status, &createdAt)
			wn := "-"
			if workerName != nil {
				wn = *workerName
			}
			fmt.Fprintf(w, "%d\t%s\t%s\t%s\t%s\t%s\t%s\n",
				id, orderNo, customerName, wn, categoryName, status, createdAt)
		}
		w.Flush()
	case "detail":
		if len(args) < 1 {
			fmt.Println("Usage: repair admin order detail <id>")
			return
		}
		id, _ := strconv.ParseInt(args[0], 10, 64)
		o, err := repository.GetOrderByID(id)
		if err != nil {
			fmt.Printf("Order not found: %v\n", err)
			return
		}
		fmt.Printf("OrderNo: %s\nStatus: %s\nDesc: %s\nAddr: %s\nCreated: %s\n",
			o.OrderNo, o.Status, o.Description, o.Address, o.CreatedAt.Format("2006-01-02 15:04"))
	default:
		fmt.Printf("Unknown action: %s\n", action)
	}
}

func adminStats() {
	var totalUsers, totalOrders, completedOrders, totalWorkers int
	repository.DB.QueryRow("SELECT COUNT(*) FROM users").Scan(&totalUsers)
	repository.DB.QueryRow("SELECT COUNT(*) FROM orders").Scan(&totalOrders)
	repository.DB.QueryRow("SELECT COUNT(*) FROM orders WHERE status='completed'").Scan(&completedOrders)
	repository.DB.QueryRow("SELECT COUNT(*) FROM workers WHERE is_verified=1").Scan(&totalWorkers)

	fmt.Println("=== Stats ===")
	fmt.Printf("Total Users:     %d\n", totalUsers)
	fmt.Printf("Verified Workers: %d\n", totalWorkers)
	fmt.Printf("Total Orders:    %d\n", totalOrders)
	fmt.Printf("Completed:       %d\n", completedOrders)
}

func printAdminUsage() {
	fmt.Println(`Admin Commands:
  repair admin category list            List categories
  repair admin category add <name>      Add category
  repair admin user list                List users
  repair admin user detail <id>         User detail
  repair admin worker verify <id>       Verify worker
  repair admin order list               List orders
  repair admin order detail <id>        Order detail
  repair admin stats                    Statistics`)
}
