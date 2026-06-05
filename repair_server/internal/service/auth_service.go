package service

import (
	"errors"
	"fmt"
	"math/rand"
	"sync"
	"time"

	"repair_server/internal/model"
	"repair_server/internal/repository"

	"golang.org/x/crypto/bcrypt"
)

// 内存验证码存储（轻量，无需 Redis）
var (
	codeStore = sync.Map{} // phone -> {code, expiry}
)

type codeEntry struct {
	Code   string
	Expiry time.Time
}

// GenerateAndSendCode 生成验证码（开发阶段打印到日志）
func GenerateAndSendCode(phone string) (string, error) {
	code := fmt.Sprintf("%06d", rand.Intn(1000000))

	// MVP: 开发阶段用固定验证码 123456，生产接短信服务商
	devCode := "123456"
	codeStore.Store(phone, codeEntry{Code: devCode, Expiry: time.Now().Add(5 * time.Minute)})

	// 返回开发用验证码（生产环境不返回）
	_ = code
	return devCode, nil
}

// VerifyCode 校验验证码
func VerifyCode(phone, code string) bool {
	val, ok := codeStore.Load(phone)
	if !ok {
		return false
	}
	entry := val.(codeEntry)
	if time.Now().After(entry.Expiry) {
		codeStore.Delete(phone)
		return false
	}
	if entry.Code != code {
		return false
	}
	codeStore.Delete(phone) // 验证通过后删除，防止重用
	return true
}

// Login 登录（仅已有用户）
func Login(phone, code string) (*model.AuthResp, error) {
	if !VerifyCode(phone, code) {
		return nil, errors.New("验证码错误或已过期")
	}

	user, err := repository.GetUserByPhone(phone)
	if err != nil {
		return nil, errors.New("用户不存在，请先注册")
	}

	token, err := GenerateToken(user.ID, user.Phone, user.Role)
	if err != nil {
		return nil, fmt.Errorf("生成token失败: %w", err)
	}

	return &model.AuthResp{Token: token, User: *user}, nil
}

// Register 注册（仅新用户）
func Register(phone, code, role string) (*model.AuthResp, error) {
	if !VerifyCode(phone, code) {
		return nil, errors.New("验证码错误或已过期")
	}

	// 检查是否已注册
	if existing, err := repository.GetUserByPhone(phone); err == nil {
		// 已有用户，直接返回登录结果（允许重复注册=登录）
		token, err := GenerateToken(existing.ID, existing.Phone, existing.Role)
		if err != nil {
			return nil, fmt.Errorf("生成token失败: %w", err)
		}
		return &model.AuthResp{Token: token, User: *existing}, nil
	}

	// 新用户注册
	user := &model.User{
		Phone:        phone,
		PasswordHash: "",
		Role:         role,
		Name:         formatPhone(phone),
	}
	if err := repository.CreateUser(user); err != nil {
		return nil, fmt.Errorf("创建用户失败: %w", err)
	}
	if role == "worker" {
		_ = repository.CreateWorker(&model.Worker{UserID: user.ID})
	}

	token, err := GenerateToken(user.ID, user.Phone, user.Role)
	if err != nil {
		return nil, fmt.Errorf("生成token失败: %w", err)
	}

	return &model.AuthResp{Token: token, User: *user}, nil
}

func formatPhone(phone string) string {
	if len(phone) >= 11 {
		return phone[:3] + "****" + phone[7:]
	}
	return phone
}

// HashPassword bcrypt 加密（备用）
func HashPassword(pwd string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(pwd), bcrypt.DefaultCost)
	return string(bytes), err
}

// CheckPassword 验证密码（备用）
func CheckPassword(hash, pwd string) bool {
	return bcrypt.CompareHashAndPassword([]byte(hash), []byte(pwd)) == nil
}
