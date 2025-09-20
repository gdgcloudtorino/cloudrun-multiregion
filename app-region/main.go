package main

import (
	"encoding/json"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"time"
)

var (
	// Mettiamo in cache la regione per evitare di interrogare il metadata server ad ogni richiesta.
	regionCache string
)

func main() {
	// Pre-carica la regione all'avvio dell'applicazione.
	regionCache = getRegion()

	http.HandleFunc("/healthz", healthCheckHandler)
	http.HandleFunc("/api/region", regionHandler)

	// Cloud Run imposta la variabile d'ambiente PORT.
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
		log.Printf("PORT non definita, uso la porta di default: %s", port)
	}

	log.Printf("Server in ascolto sulla porta %s", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatalf("Errore nell'avvio del server: %v", err)
	}
}

// healthCheckHandler gestisce le richieste di health check dal Load Balancer.
func healthCheckHandler(w http.ResponseWriter, r *http.Request) {
	// Questo handler risponde semplicemente con 200 OK se l'app è in esecuzione.
	// Aggiungiamo una logica per simulare un fallimento a comando.
	if os.Getenv("SIMULATE_FAILURE") == "true" {
		log.Println("Simulazione fallimento: l'health check risponderà con 503.")
		w.WriteHeader(http.StatusServiceUnavailable)
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{"status": "unhealthy"})
		return
	}

	// Il Load Balancer lo userà per verificare che l'istanza sia attiva e funzionante.
	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

// regionHandler gestisce le richieste in ingresso e risponde con la regione.
func regionHandler(w http.ResponseWriter, r *http.Request) {
	hostname, _ := os.Hostname()
	response := map[string]string{
		"message":  "Hello from the multi-region demo!",
		"region":   regionCache,
		"hostname": hostname, // Utile per vedere se l'istanza cambia
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// getRegion recupera la regione dal metadata server di GCP.
// Restituisce "local" se non riesce a recuperare la regione (es. in esecuzione locale).
func getRegion() string {
	metadataURL := "http://metadata.google.internal/computeMetadata/v1/instance/region"

	client := &http.Client{
		Timeout: 2 * time.Second, // Evita attese lunghe se il server non è raggiungibile
	}
	req, err := http.NewRequest("GET", metadataURL, nil)
	if err != nil {
		log.Printf("Non è stato possibile creare la richiesta al metadata server: %v", err)
		return "local"
	}

	// L'header Metadata-Flavor è obbligatorio.
	req.Header.Set("Metadata-Flavor", "Google")

	resp, err := client.Do(req)
	if err != nil {
		log.Printf("Non è stato possibile contattare il metadata server (probabilmente stai eseguendo in locale): %v", err)
		return "local"
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		log.Printf("Il metadata server ha risposto con status non-200: %d", resp.StatusCode)
		return "local"
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Printf("Impossibile leggere la risposta dal metadata server: %v", err)
		return "local"
	}

	// La risposta è nel formato "projects/PROJECT_NUMBER/regions/REGION". Vogliamo solo l'ultima parte.
	parts := strings.Split(string(body), "/")
	region := parts[len(parts)-1]

	log.Printf("Regione recuperata con successo: %s", region)
	return region
}
