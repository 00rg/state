package main

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"os"

	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/exporters/stdout/stdouttrace"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/resource"
	sdktrace "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.12.0"
	"go.opentelemetry.io/otel/trace"
)

var (
	port        = "8080"
	externalURL = "https://httpbin.org/get"
	version     = "v0.0.1"

	tracer         trace.Tracer
	tracerProvider sdktrace.TracerProvider
)

func init() {
	p, ok := os.LookupEnv("PORT")
	if ok {
		port = p
	}

	url, ok := os.LookupEnv("EXTERNAL_URL")
	if ok {
		externalURL = url
	}

	ctx := context.Background()

	exporter, err := newOTLPExporter(ctx)
	if err != nil {
		fmt.Printf("Error creating trace exporter: %v", err)
		os.Exit(1)
	}

	tracerProvider, err := newTraceProvider(exporter)
	if err != nil {
		fmt.Printf("Error creating trace provider: %v", err)
		os.Exit(1)
	}

	otel.SetTracerProvider(tracerProvider)

	tracer = tracerProvider.Tracer("hello")

	otel.SetTextMapPropagator(propagation.TraceContext{})
}

func main() {
	if err := realMain(); err != nil {
		panic(err)
	}
}

func realMain() error {
	defer shutdown()

	mux := http.NewServeMux()

	mux.HandleFunc("/version", func(w http.ResponseWriter, r *http.Request) {
		io.WriteString(w, version)
	})

	mux.HandleFunc("/external", func(w http.ResponseWriter, r *http.Request) {
		client := http.Client{
			Transport: otelhttp.NewTransport(http.DefaultTransport),
		}

		ctx := r.Context()

		req, err := http.NewRequestWithContext(ctx, "GET", externalURL, nil)
		if err != nil {
			writeResponse(w, http.StatusInternalServerError, err.Error())
			return
		}

		res, err := client.Do(req)
		if err != nil {
			writeResponse(w, http.StatusInternalServerError, err.Error())
			return
		}

		defer res.Body.Close()

		body, err := io.ReadAll(res.Body)
		if err != nil {
			writeResponse(w, http.StatusInternalServerError, err.Error())
			return
		}

		writeResponse(w, res.StatusCode, string(body))
	})

	handler := otelhttp.NewHandler(mux, "hello-http-middleware")

	server := &http.Server{
		Addr:    ":" + port,
		Handler: handler,
	}

	fmt.Println("HTTP server listening on port " + port)

	return server.ListenAndServe()
}

func newStdoutExporter(ctx context.Context) (sdktrace.SpanExporter, error) {
	return stdouttrace.New(
		stdouttrace.WithPrettyPrint(),
		stdouttrace.WithoutTimestamps(),
	)
}

func newOTLPExporter(ctx context.Context) (*otlptrace.Exporter, error) {
	client := otlptracehttp.NewClient()
	return otlptrace.New(ctx, client)
}

func newTraceProvider(exp sdktrace.SpanExporter) (*sdktrace.TracerProvider, error) {
	r, err := resource.Merge(
		resource.Default(),
		resource.NewWithAttributes(
			"",
			// semconv.SchemaURL,
			semconv.ServiceNameKey.String("hello"),
			semconv.ServiceVersionKey.String("v0.1.0"),
			semconv.DeploymentEnvironmentKey.String("development"),
		),
	)

	if err != nil {
		return nil, err
	}

	return sdktrace.NewTracerProvider(
		sdktrace.WithBatcher(exp),
		sdktrace.WithResource(r),
	), nil
}

func writeResponse(w http.ResponseWriter, status int, body string) {
	w.WriteHeader(status)
	io.WriteString(w, body)
}

func shutdown() {
	if err := tracerProvider.Shutdown(context.Background()); err != nil {
		fmt.Printf("Error shutting down tracer provider: %v", err)
		os.Exit(1)
	}
}
