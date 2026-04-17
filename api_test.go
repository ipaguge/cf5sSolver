package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"testing"
)

// Req 请求结构
type Req struct {
	Url            string `json:"url"`            // 访问网址
	Proxy          *Proxy `json:"proxy"`          // 代理
	Timeout        int    `json:"timeout"`        // 总超时时间 单位秒
	RetryOnFailure int    `json:"retryOnFailure"` // 失败重试次数
	OutputBody     bool   `json:"outputBody"`     // 是否返回body
	OutputDelay    int    `json:"outputDelay"`    // 是否延迟返回 就是处理完毕后等待多时秒返回 适用于网页加载完毕等 单位秒
}

// Res 响应结构
type Res struct {
	Status  string `json:"status"`  // 状态
	Message string `json:"message"` // 错误信息
	Data    Data   `json:"data"`
}
type Data struct {
	IsVerifyPage   bool   `json:"isVerifyPage"`   // 页面是不是需要验证 如无需验证的网页
	UserAgent      string `json:"userAgent"`      // 当前使用的UserAgent CF五秒盾Cookies与UserAgent必须配对
	Cookies        string `json:"cookies"`        // 当前的Cookies
	TurnstileToken string `json:"turnstileToken"` // Turnstile Token
	Body           string `json:"body"`
}
type Proxy struct {
	ProxyURL string `json:"url"` // 必须是连接 如 http://1.1.1.1:1158 socks5://1.1.1.1:1158 需要注意的是 socks5账号密码验证存在问题 受限于浏览浏览器核心
	Username string `json:"username"`
	Password string `json:"password"`
}

func flarePost(flareApi string, req Req) (res Res, err error) {
	body, _ := json.Marshal(req)
	resp, err := http.Post(flareApi, "application/json", bytes.NewReader(body))
	if err != nil {
		err = fmt.Errorf("sessions.create err is %s", err.Error())
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		err = fmt.Errorf("sessions.create status is %d", resp.StatusCode)
		return
	}

	raw, err := io.ReadAll(resp.Body)
	if err != nil {
		return
	}

	err = json.Unmarshal(raw, &res)
	if err != nil {
		err = fmt.Errorf("sessions.create unmarshal err is %s", err.Error())
		return
	}
	return
}

func TestApi(t *testing.T) {
	proxy := Proxy{
		ProxyURL: "http://gw.dataimpulse.com:12000",
		Username: "3dc15c8ce2801c6e0794__cr.jp",
		Password: "01845531e08ad1a5",
	}

	// 测试turnstile验证 并且得到token
	req, err := flarePost("http://10.0.0.120:8901/turnstile", Req{
		Url:         "https://core.particle.network/cloudflare.html",
		Proxy:       &proxy,
		OutputDelay: 0,
		OutputBody:  false,
		Timeout:     90,
	})
	if err != nil {
		log.Print("turnstile验证 失败", err.Error())
	}

	if req.Status != "success" {
		log.Print("turnstile验证 失败", req.Message)
	}

	if req.Status == "success" {
		log.Print("turnstile验证 成功 token ", req.Data.TurnstileToken)
	}

	// 测试5秒盾验证 并且得到cookie
	req, err = flarePost("http://10.0.0.120:8901/cloudflare", Req{
		Url:         "https://zhile.io/",
		Proxy:       &proxy,
		OutputDelay: 0,
		OutputBody:  false,
		Timeout:     90,
	})

	if err != nil {
		log.Print("5秒盾验证 失败", err.Error())
	}

	if req.Status != "success" {
		log.Print("5秒盾验证 失败", req.Message)
	}

	if req.Status == "success" {
		log.Print("5秒盾验证 成功 token ", req.Data.TurnstileToken)
	}

}
