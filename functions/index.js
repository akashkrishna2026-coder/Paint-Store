// functions/index.js
const {onValueCreated} = require("firebase-functions/v2/database");
const {initializeApp} = require("firebase-admin/app");
const {getMessaging} = require("firebase-admin/messaging");

// Initialize Admin SDK once per instance
initializeApp();

// Sends a device push when a new in-app notification is created at
// users/{uid}/notifications/{nid}
exports.notifyOnOrderUpdateV2 = onValueCreated(
    {region: "us-central1", ref: "/users/{uid}/notifications/{nid}"},
    async (event) => {
      const data = (event.data && event.data.val()) || {};
      const uid = event.params.uid;

      const title = data.title || "Order Update";
      const body = data.message || "Your order status changed";
      const orderId = String(data.orderId || "");
      const status = String(data.status || "");

      const message = {
        topic: `user_${uid}`,
        notification: {title, body},
        data: {
          type: "order_status",
          orderId,
          status,
          nid: String(event.params.nid),
        },
        android: {priority: "high"},
      };

      await getMessaging().send(message);
      return;
    },
);
