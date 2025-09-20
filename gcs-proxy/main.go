package main

import (
	"bytes"
	"context"
	"encoding/json"
	"image"
	_ "image/gif"
	"image/jpeg"
	_ "image/png"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/nfnt/resize"

	"cloud.google.com/go/storage"
)

// gcsProxy contiene la configurazione per fare da proxy verso un bucket GCS.
type gcsProxy struct {
	bucket *storage.BucketHandle
}

func main() {
	// --- Configurazione ---
	// Il nome del bucket viene passato tramite variabile d'ambiente.
	bucketName := os.Getenv("GCS_BUCKET_NAME")
	if bucketName == "" {
		log.Fatal("La variabile d'ambiente GCS_BUCKET_NAME deve essere impostata.")
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// --- Inizializzazione ---
	// Il client Go rileverà automaticamente le credenziali nell'ambiente Cloud Run.
	ctx := context.Background()
	storageClient, err := storage.NewClient(ctx)
	if err != nil {
		log.Fatalf("Impossibile creare il client di Google Cloud Storage: %v", err)
	}
	defer storageClient.Close()

	proxy := &gcsProxy{
		bucket: storageClient.Bucket(bucketName),
	}

	// --- Routing ---
	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", healthCheckHandler)
	// Il gestore del proxy si occuperà di tutte le altre richieste.
	mux.Handle("/", proxy)

	// --- Avvio del Server ---
	log.Printf("Reverse proxy per il bucket '%s' in ascolto sulla porta %s", bucketName, port)
	if err := http.ListenAndServe(":"+port, mux); err != nil {
		log.Fatalf("Errore nell'avvio del server: %v", err)
	}
}

// ServeHTTP implementa l'interfaccia http.Handler per il nostro proxy.
func (p *gcsProxy) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// Supportiamo solo richieste GET e HEAD.
	if r.Method != http.MethodGet && r.Method != http.MethodHead {
		http.Error(w, "Metodo non supportato", http.StatusMethodNotAllowed)
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 50*time.Second)
	defer cancel()

	// Il nome dell'oggetto è il percorso della richiesta, senza la slash iniziale.
	objectName := strings.TrimPrefix(r.URL.Path, "/")
	// Se il percorso è vuoto (richiesta a "/"), serviamo 'index.html' di default.
	if objectName == "" {
		objectName = "index.html"
	}

	log.Printf("Richiesta per l'oggetto: %s", objectName)

	obj := p.bucket.Object(objectName)

	// Recuperiamo gli attributi per verificare l'esistenza e ottenere i metadati.
	attrs, err := obj.Attrs(ctx)
	if err == storage.ErrObjectNotExist {
		log.Printf("Oggetto non trovato: %s", objectName)
		http.NotFound(w, r)
		return
	}
	if err != nil {
		log.Printf("Errore nel recuperare gli attributi dell'oggetto %s: %v", objectName, err)
		http.Error(w, "Errore interno del server", http.StatusInternalServerError)
		return
	}

	// Impostiamo gli header della risposta usando i metadati dell'oggetto GCS.
	w.Header().Set("Content-Type", attrs.ContentType)
	w.Header().Set("Content-Length", strconv.FormatInt(attrs.Size, 10))
	if attrs.CacheControl != "" {
		w.Header().Set("Cache-Control", attrs.CacheControl)
	}
	w.Header().Set("Last-Modified", attrs.Updated.Format(http.TimeFormat))
	w.Header().Set("ETag", attrs.Etag)

	// Per le richieste HEAD, abbiamo finito dopo aver impostato gli header.
	if r.Method == http.MethodHead {
		w.WriteHeader(http.StatusOK)
		return
	}

	// Per le richieste GET, leggiamo l'immagine, la ridimensioniamo e la restituiamo.
	reader, err := obj.NewReader(ctx)
	if err != nil {
		log.Printf("Errore nella creazione del reader per l'oggetto %s: %v", objectName, err)
		http.Error(w, "Errore interno del server", http.StatusInternalServerError)
		return
	}
	defer reader.Close()

	// Decodifichiamo l'immagine. I blank import di image/png, image/jpeg, etc.
	// registrano i decoder necessari.
	img, _, err := image.Decode(reader)
	if err != nil {
		log.Printf("Errore nella decodifica dell'immagine %s: %v", objectName, err)
		http.Error(w, "Impossibile processare il file come immagine", http.StatusInternalServerError)
		return
	}

	// Creiamo un thumbnail di 300x300 pixel mantenendo l'aspect ratio.
	thumbnail := resize.Thumbnail(300, 300, img, resize.Lanczos3)

	// Codifichiamo il thumbnail in un buffer come JPEG.
	buf := new(bytes.Buffer)
	if err := jpeg.Encode(buf, thumbnail, &jpeg.Options{Quality: 85}); err != nil {
		log.Printf("Errore nella codifica del thumbnail %s: %v", objectName, err)
		http.Error(w, "Errore interno del server", http.StatusInternalServerError)
		return
	}

	// Inviamo la risposta con il thumbnail.
	w.Header().Set("Content-Type", "image/jpeg")
	w.Header().Set("Content-Length", strconv.Itoa(buf.Len()))
	w.Write(buf.Bytes())
}

// healthCheckHandler gestisce le richieste di health check.
func healthCheckHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}
