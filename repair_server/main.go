package main

import (
	"flag"
	"fmt"
	"os"

	"repair_server/cmd/admin"
	"repair_server/cmd/server"
)

func main() {
	if len(os.Args) < 2 {
		printUsage()
		os.Exit(1)
	}

	switch os.Args[1] {
	case "server":
		runServer()
	case "admin":
		admin.Run(os.Args[2:])
	default:
		printUsage()
		os.Exit(1)
	}
}

func runServer() {
	fs := flag.NewFlagSet("server", flag.ExitOnError)
	port := fs.String("port", "8080", "服务端口")
	dbPath := fs.String("db", "./data/repair.db", "数据库文件路径")
	dataDir := fs.String("data-dir", "./data", "数据目录")

	fs.Parse(os.Args[2:])

	server.Run(server.Config{
		Port:    *port,
		DBPath:  *dbPath,
		DataDir: *dataDir,
	})
}

func printUsage() {
	fmt.Println(`Repair Server - 家政维修服务平台

用法:
  repair server [参数]    启动 API 服务
  repair admin <命令>     管理工具

服务参数:
  --port PORT             服务端口 (默认 8080)
  --db PATH              数据库路径 (默认 ./data/repair.db)
  --data-dir DIR          数据目录 (默认 ./data)

管理命令:
  repair admin category list            查看类目
  repair admin category add <name>      添加类目
  repair admin user list                用户列表
  repair admin user detail <id>         用户详情
  repair admin worker verify <id>       审核师傅
  repair admin order list               订单列表
  repair admin order detail <id>        订单详情
  repair admin stats                    今日统计`)
}
