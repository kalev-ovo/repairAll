package handler

import (
	"net/http"

	"repair_server/internal/repository"

	"github.com/gin-gonic/gin"
)

// categoryNode 类目树节点
type categoryNode struct {
	ID       int64          `json:"id"`
	Name     string         `json:"name"`
	Icon     string         `json:"icon"`
	Children []categoryNode `json:"children,omitempty"`
}

// GetCategories 获取服务类目（树形结构）
func GetCategories(c *gin.Context) {
	cats, err := repository.GetCategories()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询失败"})
		return
	}

	parentMap := make(map[int64][]categoryNode)
	var roots []categoryNode

	for _, cat := range cats {
		node := categoryNode{ID: cat.ID, Name: cat.Name, Icon: cat.Icon}
		if cat.ParentID == nil {
			roots = append(roots, node)
		} else {
			parentMap[*cat.ParentID] = append(parentMap[*cat.ParentID], node)
		}
	}

	// 填充子节点
	for i := range roots {
		fillChildren(&roots[i], parentMap)
	}

	c.JSON(http.StatusOK, roots)
}

func fillChildren(node *categoryNode, parentMap map[int64][]categoryNode) {
	if children, ok := parentMap[node.ID]; ok {
		node.Children = children
		for i := range node.Children {
			fillChildren(&node.Children[i], parentMap)
		}
	}
}
