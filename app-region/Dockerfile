# ---- Build Stage ----
# Utilizziamo un'immagine Go ufficiale per compilare l'applicazione.
# Questa tecnica è conosciuta come "multi-stage build".
FROM golang:1.21-alpine as builder

# Impostiamo la directory di lavoro all'interno del container
WORKDIR /app

# Copiamo i file go.mod e go.sum per scaricare le dipendenze
COPY go.mod go.sum ./

# Scarichiamo le dipendenze. Verranno messe in cache se i file mod/sum non cambiano.
RUN go mod download

# Copiamo il resto del codice sorgente
COPY . .

# Compiliamo l'applicazione Go.
# CGO_ENABLED=0 crea un binario statico, ideale per immagini minimali come distroless.
RUN CGO_ENABLED=0 go build -o /app-server .

# ---- Run Stage ----
# Utilizziamo un'immagine "distroless" che contiene solo la nostra applicazione e le sue dipendenze.
# È un'ottima scelta per la sicurezza e per ridurre le dimensioni dell'immagine.
FROM gcr.io/distroless/static-debian11
COPY --from=builder /app-server /app-server
CMD ["/app-server"]
