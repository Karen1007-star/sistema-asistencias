
import prisma from "../config/prisma.js";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";

export const login = async (req, res) => {
  try {
    const { identificador, password } = req.body;

    if (!identificador || !password) {
      return res.status(400).json({
        ok: false,
        mensaje: "El DNI o correo y la contraseña son obligatorios",
      });
    }

    if (!process.env.JWT_SECRET) {
      console.error("Falta configurar JWT_SECRET");
      return res.status(500).json({
        ok: false,
        mensaje: "Error de configuración del servidor",
      });
    }

    const persona = await prisma.persona.findFirst({
      where: {
        OR: [
          { dni: identificador },
          { correo: identificador },
        ],
      },
      include: {
        usuario: true,
      },
    });

    if (
      !persona ||
      !persona.usuario ||
      !persona.usuario.activo ||
      !persona.activo
    ) {
      return res.status(401).json({
        ok: false,
        mensaje: "Credenciales incorrectas",
      });
    }

    const passwordValida = await bcrypt.compare(
      password,
      persona.usuario.passwordHash
    );

    if (!passwordValida) {
      return res.status(401).json({
        ok: false,
        mensaje: "Credenciales incorrectas",
      });
    }

    const token = jwt.sign(
      {
        usuarioId: persona.usuario.id,
        personaId: persona.id,
        rol: persona.usuario.rol,
      },
      process.env.JWT_SECRET,
      { expiresIn: "8h" }
    );

    await prisma.usuario.update({
      where: { id: persona.usuario.id },
      data: { ultimoAcceso: new Date() },
    });

    return res.status(200).json({
      ok: true,
      mensaje: "Inicio de sesión exitoso",
      token,
      usuario: {
        id: persona.usuario.id,
        personaId: persona.id,
        dni: persona.dni,
        nombres: persona.nombres,
        apellidos: persona.apellidos,
        correo: persona.correo,
        rol: persona.usuario.rol,
        debeCambiarPassword:
          persona.usuario.debeCambiarPassword,
      },
    });
  } catch (error) {
    console.error("Error en login:", error);

    return res.status(500).json({
      ok: false,
      mensaje: "Error interno del servidor",
    });
  }
};
