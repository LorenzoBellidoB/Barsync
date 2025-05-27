const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.notifyWaiter = functions.https.onRequest(async (req, res) => {
  const {token, title, body} = req.body;

  if (!token || !title || !body) {
    return res.status(400).send("Faltan parámetros");
  }

  const message = {
    notification: {
      title,
      body,
    },
    token,
  };

  try {
    const response = await admin.messaging().send(message);
    console.log("Notificación enviada:", response);
    return res.status(200).send("Notificación enviada correctamente");
  } catch (error) {
    console.error("Error al enviar la notificación:", error);
    return res.status(500).send("Error enviando la notificación");
  }
});
