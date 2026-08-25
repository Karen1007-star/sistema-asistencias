import "dotenv/config";
import express from "express";
import cors from "cors";
import prisma from "./config/prisma.js";

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

    app.get("/api/salud", async (req, res) => {
        try {
            await prisma.$queryRaw`SELECT 1`;

            res.status(200).json({
                ok: true,
                mensaje: "API del sistema de asistencias funcionando",
                baseDeDatos: "conectada",
            });
            
        } catch (error) {
            console.error("Error al conectar con PostgreSQL:", error);
            
            res.status(503).json({
                ok: false,
                mensaje: "La API funciona, pero no pudo conectarse con la base de datos",
                baseDeDatos: "desconectada",
            });
        }
    });

app.listen(PORT, () => {
  console.log(`Servidor ejecutándose en http://localhost:${PORT}`);
});