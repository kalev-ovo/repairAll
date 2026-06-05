package server

import (
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"

	"repair_server/internal/handler"
	"repair_server/internal/middleware"
	"repair_server/internal/repository"

	"github.com/gin-gonic/gin"
)

// Config 服务配置
type Config struct {
	Port    string
	DBPath  string
	DataDir string
}

// Run 启动 API 服务
func Run(cfg Config) {
	// 初始化数据库
	if err := repository.InitDB(cfg.DBPath); err != nil {
		log.Fatalf("Failed to init database: %v", err)
	}

	// 设置上传目录
	handler.UploadDir = cfg.DataDir + "/uploads"

	// Gin 路由
	r := gin.Default()
	r.Use(middleware.CORS())

	// 静态文件服务（上传的文件）
	r.Static("/uploads", cfg.DataDir+"/uploads")

	api := r.Group("/api/v1")
	{
		// 认证（无需 JWT）
		auth := api.Group("/auth")
		{
			auth.POST("/send-code", handler.SendCode)
			auth.POST("/login", handler.Login)
			auth.POST("/register", handler.Register)
		}

		// 需要 JWT 认证
		authorized := api.Group("")
		authorized.Use(middleware.JWTAuth())
		{
			// 用户
			authorized.GET("/user/profile", handler.GetProfile)
			authorized.PUT("/user/profile", handler.UpdateProfile)
			authorized.POST("/user/switch-role", handler.SwitchRole)
			authorized.PUT("/user/worker-profile", handler.UpdateWorkerProfile)
			authorized.GET("/user/worker-stats", handler.GetWorkerStats)
			authorized.POST("/user/worker/submit-verify", handler.SubmitWorkerVerify)
			authorized.GET("/user/worker/:id", handler.GetWorkerDetail)

			// 类目
			authorized.GET("/categories", handler.GetCategories)

			// 订单
			authorized.POST("/orders", handler.CreateOrder)
			authorized.GET("/orders", handler.ListOrders)
			authorized.GET("/orders/:id", handler.GetOrder)
			authorized.PUT("/orders/:id/accept", handler.AcceptOrder)
			authorized.PUT("/orders/:id/arrive", handler.ArriveOrder)
			authorized.PUT("/orders/:id/complete", handler.CompleteOrder)
			authorized.PUT("/orders/:id/cancel", handler.CancelOrder)

			// 评价
			authorized.POST("/reviews", handler.CreateReview)
			authorized.GET("/reviews/user/:id", handler.GetUserReviews)

			// 聊天记录
			authorized.GET("/chat/history", handler.GetChatHistory)

			// 文件上传
			authorized.POST("/upload/image", handler.UploadImage)
		}

		// 管理端（JWT + role=admin，MVP阶段仅JWT保护）
		admin := api.Group("/admin")
		admin.Use(middleware.JWTAuth())
		{
			admin.GET("/pending-workers", handler.ListPendingWorkers)
			admin.PUT("/worker/:id/verify", handler.AdminVerifyWorker)
		}

		// WebSocket
		api.GET("/ws/chat", handler.HandleChat)
	}

	// 优雅关闭
	go func() {
		quit := make(chan os.Signal, 1)
		signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
		<-quit
		log.Println("Shutting down server...")
		os.Exit(0)
	}()

	addr := fmt.Sprintf(":%s", cfg.Port)
	log.Printf("Server starting on %s", addr)
	if err := r.Run(addr); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
