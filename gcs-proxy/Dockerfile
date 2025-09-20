# ---- Build Stage ----
FROM golang:1.21-alpine as builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 go build -o /proxy-server .

# ---- Run Stage ----
FROM gcr.io/distroless/static-debian11

COPY --from=builder /proxy-server /proxy-server

CMD ["/proxy-server"]
