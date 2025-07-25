'use strict';

const express = require('express');
const path = require('path');

const PORT = 8080;
const HOST = '0.0.0.0';

const app = express();

// Serve a simple HTML page
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>My First Containerized Node App</title>
      <style>
        body {
          margin: 0;
          font-family: Arial, sans-serif;
          background: linear-gradient(135deg, #1e3c72, #2a5298);
          color: white;
          text-align: center;
          display: flex;
          flex-direction: column;
          justify-content: center;
          align-items: center;
          height: 100vh;
        }
        h1 {
          font-size: 3em;
          margin-bottom: 0.5em;
        }
        p {
          font-size: 1.2em;
          margin-top: 0;
        }
        .button {
          margin-top: 20px;
          padding: 10px 20px;
          background-color: #ff9800;
          color: red;
          border: none;
          border-radius: 5px;
          cursor: pointer;
          font-size: 1em;
          transition: background 0.3s;
        }
        .button:hover {
          background-color: #e68900;
        }
      </style>
    </head>
    <body>
      <h1>Welcome to My Node App!</h1>
      <p>This is my first containerized Node.js application running on ECS.</p>
      <button class="button" onclick="alert('Hello from your containerized app!')">Click Me</button>
    </body>
    </html>
  `);
});

app.listen(PORT, HOST, () => {
  console.log(`Running on http://${HOST}:${PORT}`);
});
