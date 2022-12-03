package main

import (
	"io"
	"net/http"
	"os"

	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
)

// The following variables are updated by -ldflags at build time.
var (
	Version     = "unknown"
	Port        = "8080"
	ExternalUrl = "https://httpbin.org/get"
)

func init() {
	if externalUrl := os.Getenv("EXTERNAL_URL"); externalUrl != "" {
		ExternalUrl = externalUrl
	}
}

func main() {
	e := echo.New()

	e.Use(middleware.Logger())
	e.Use(middleware.Recover())

	e.GET("/", func(c echo.Context) error {
		return c.String(http.StatusOK, "Hello!")
	})

	e.GET("/version", func(c echo.Context) error {
		return c.String(http.StatusOK, Version)
	})

	e.GET("/external", func(c echo.Context) error {
		resp, err := http.Get(ExternalUrl)
		if err != nil {
			return err
		}

		defer resp.Body.Close()

		body, err := io.ReadAll(resp.Body)
		if err != nil {
			return err
		}

		return c.String(resp.StatusCode, string(body))
	})

	e.Logger.Fatal(e.Start(":" + Port))
}
