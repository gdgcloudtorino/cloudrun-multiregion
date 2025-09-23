package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"strconv"
)

var (
	// Mettiamo in cache la regione per evitare di interrogare il metadata server ad ogni richiesta.
	regionCache string
)

func main() {
	// Pre-carica la regione all'avvio dell'applicazione.
	regionCache = os.Getenv("REGION")

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
	ko := os.Getenv("SIMULATE_FAILURE") == "true"
	status := !ko
	response := map[string]string{
		"message":  "Hello from the multi-region demo!",
		"region":   regionCache,
		"hostname": hostname,
		"status":   strconv.FormatBool(status),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}
