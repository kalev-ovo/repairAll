FROM golang:1.23-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o repair .

FROM alpine:3.20
RUN apk add --no-cache ca-certificates tzdata
WORKDIR /app
COPY --from=builder /app/repair .

RUN mkdir -p /app/data/uploads
EXPOSE 8080

ENV JWT_SECRET=change_me_in_production

CMD ["./repair", "server", "--port", "8080", "--db", "/app/data/repair.db", "--data-dir", "/app/data"]
