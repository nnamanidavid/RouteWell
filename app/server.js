require("dotenv").config();
const express = require("express");
const { Pool } = require("pg");

const app = express();
const port = process.env.APP_PORT || 8080;

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT || 5432,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

// Health check — useful for confirming Web -> App connectivity independently of the DB
app.get("/api/health", (req, res) => {
  res.json({ status: "ok", tier: "app" });
});

// Increments and returns a visit count stored in the DB tier.
// Proves App -> DB connectivity end to end.
app.get("/api/visits", async (req, res) => {
  try {
    const result = await pool.query(
      "UPDATE visits SET count = count + 1 WHERE id = 1 RETURNING count"
    );
    res.json({ count: result.rows[0].count });
  } catch (err) {
    console.error("DB query failed:", err.message);
    res.status(500).json({ error: "could not reach database tier" });
  }
});

// Bind to 0.0.0.0 so the Web subnet can reach it, but the NSG on this
// subnet must still block anything except traffic from the Web subnet.
app.listen(port, "0.0.0.0", () => {
  console.log(`App tier listening on port ${port}`);
});
