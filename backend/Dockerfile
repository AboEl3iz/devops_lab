# ── Stage 1: Build ────────────────────────────────────────────────────────────
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Download dependencies first (layer cache friendly)
COPY go.mod go.sum ./
RUN go mod download

# Copy source and build a static binary
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# ── Stage 2: Run ──────────────────────────────────────────────────────────────
FROM alpine:3.19

# ca-certificates for TLS, tzdata for time zone support
RUN apk --no-cache add ca-certificates tzdata

WORKDIR /root/

COPY --from=builder /app/main .

EXPOSE 8080

CMD ["./main"]
