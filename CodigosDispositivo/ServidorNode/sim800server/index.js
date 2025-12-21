const express = require("express");
const admin = require("firebase-admin");

const app = express();
app.use(express.json()); // ✅ Maneja correctamente JSON

// Configura tu servicio de Firebase
const serviceAccount = require("./tesis-aiq-firebase-adminsdk-fbsvc-5a31bf1149.json");

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
});

// Ignora campos undefined (opcional, buena práctica)
admin.firestore().settings({ ignoreUndefinedProperties: true });

const db = admin.firestore();

// Ruta para recibir datos desde SIM900 / CURL
app.post("/datos", async (req, res) => {
    try {
        console.log("📩 Datos recibidos:", req.body);

        const {
            humedad,
            no2,
            o3,
            prediccion,
            temperatura,
            timestamp,
            latitud,
            longitud,
        } = req.body;

        // Validar que latitud y longitud existan
        if (latitud === undefined || longitud === undefined) {
            return res
                .status(400)
                .send("❌ Faltan coordenadas (latitud o longitud).");
        }

        // Crear el GeoPoint
        const ubicacion = new admin.firestore.GeoPoint(
            parseFloat(latitud),
            parseFloat(longitud)
        );
        // Crear documento
        const data = {
            humedad: parseFloat(humedad),
            no2: parseFloat(no2),
            o3: parseFloat(o3),
            prediccion: parseInt(prediccion),
            temperatura: parseFloat(temperatura),
            timestamp: parseInt(timestamp),
            ubicacion: ubicacion,
        };
        // Guardar en Firestore con timestamp como ID
        await db.collection("registros").doc(String(timestamp)).set(data);
        console.log("✅ Datos guardados correctamente:", data);
        res.status(200).json({
            // mensaje: "✅ Datos guardados en Firestore con GeoPoint"
            mensaje: "1"
           // datos_recibidos: data,
        });
    } catch (err) {
        console.error("❌ Error al guardar:", err);
        res.status(500).send("Error al guardar en Firestore: " + err);
    }
});

// Iniciar servidor
app.listen(process.env.PORT || 3000, () => {
    console.log("🚀 Servidor iniciado en puerto 3000");
});
