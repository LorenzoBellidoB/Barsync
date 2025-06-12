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
    android: {
      priority: "high",
      notification: {title, body},
    },
    apns: {
      headers: {"apns-priority": "10"},
      payload: {aps: {sound: "default"}},
    },
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


exports.deleteUserByEmail = functions.https.onCall(async (data, context) => {
  const email = data.email;
  console.log("Recibido email:", email);
  try {
    const userRecord = await admin.auth().getUserByEmail(email);
    await admin.auth().deleteUser(userRecord.uid);
    console.log(`Usuario ${email} eliminado.`);
    return {success: true};
  } catch (error) {
    console.error("Error eliminando usuario:", error);
    throw new functions.https.HttpsError("not-found", error.message);
  }
});
