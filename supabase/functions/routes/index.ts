// deno-lint-ignore-file

// Suivre ce guide pour l'intégration de Deno avec Supabase
// https://deno.land/manual/getting_started/setup_your_environment

// Importation des définitions des API de Supabase
import "jsr:@supabase/functions-js/edge-runtime.d.ts";


type Coordinates = {
  latitude: number;
  longitude: number;
};

// Démarrer le serveur Deno
Deno.serve(async (req) => {
  try {
    // Vérifier que la requête est bien de type POST
    if (req.method !== "POST") {
      return new Response(JSON.stringify({ error: "Method Not Allowed" }), {
        status: 405,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Extraire les données de la requête
    const { origin, destination }: { origin: Coordinates; destination: Coordinates } = 
      await req.json();

    // Vérifier si les coordonnées sont valides
    if (!origin || !destination) {
      return new Response(JSON.stringify({ error: "Missing coordinates" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Récupérer la clé API depuis les variables d'environnement
    const apiKey = Deno.env.get("GOOGLE_MAPS_API_KEY");

    if (!apiKey) {
      return new Response(JSON.stringify({ error: "Missing API key" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Construire la requête vers l'API Google Maps
    const response = await fetch(
      `https://routes.googleapis.com/directions/v2:computeRoutes?key=${apiKey}`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Goog-FieldMask":
            "routes.duration, routes.distanceMeters, routes.polyline, routes.legs.polyline",
        },
        body: JSON.stringify({
          origin: { location: { latLng: origin } },
          destination: { location: { latLng: destination } },
          travelMode: "DRIVE", // "DRIVE" est la valeur correcte dans Google Maps API
          polylineEncoding: "GEO_JSON_LINESTRING",
        }),
      },
    );

    // Vérifier si la requête vers Google Maps a réussi
    if (!response.ok) {
      const errorText = await response.text();
      return new Response(JSON.stringify({ error: "Google API error", details: errorText }), {
        status: response.status,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Convertir la réponse en JSON
    const data = await response.json();
    const res=data.routes[0];

    // Retourner la réponse
    return new Response(JSON.stringify(data), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    // Gestion des erreurs internes
    return new Response(JSON.stringify({ error: "Internal Server Error", details: (error as Error).message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
/* To invoke locally:

  1. Run supabase start (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/routes' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"origin":{"latitude":37.7749,"longitude":-122.4194},"destination":{"latitude":37.7849,"longitude":-122.4294}}'

*/ 



