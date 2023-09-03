const username = process.env.WEB_USERNAME || "admin";
const password = process.env.WEB_PASSWORD || "password";
const url = process.env.RENDER_EXTERNAL_URL;
const port = process.env.PORT || 3000;
const express = require("express");
const app = express();
var exec = require("child_process").exec;
const os = require("os");
const { legacyCreateProxyMiddleware } = require("http-proxy-middleware");
var request = require("request");
var fs = require("fs");
var path = require("path");
const auth = require("basic-auth");

app.get("/", function (req, res) {
  res.status(200).send("hello world");
});

// page access password
app.use((req, res, next) => {
  const user = auth(req);
  if (user && user.name === username && user.pass === password) {
    return next();
  }
  res.set("WWW-Authenticate", 'Basic realm="Node"');
  return res.status(401).send();
});

//Get the system process table
app.get("/status", function (req, res) {
  let cmdStr = "pm2 list; ps -ef";
  exec(cmdStr, function (err, stdout, stderr) {
    if (err) {
      res.type("html").send("<pre>command line execution error：\n" + err + "</pre>");
    } else {
      res.type("html").send("<pre>Get daemon and system process tables：\n" + stdout + "</pre>");
    }
  });
});

//Get the system listening port
app.get("/listen", function (req, res) {
    let cmdStr = "ss -nltp";
    exec(cmdStr, function (err, stdout, stderr) {
      if (err) {
        res.type("html").send("<pre>command line execution error：\n" + err + "</pre>");
      } else {
        res.type("html").send("<pre>Get the system listening port：\n" + stdout + "</pre>");
      }
    });
  });

//Get node data
app.get("/list", function (req, res) {
    let cmdStr = "bash argo.sh";
    exec(cmdStr, function (err, stdout, stderr) {
      if (err) {
        res.type("html").send("<pre>command line execution error：\n" + err + "</pre>");
      }
      else {
        res.type("html").send("<pre>node data：\n\n" + stdout + "</pre>");
      }
    });
  });

//Get system version, memory information
app.get("/info", function (req, res) {
  let cmdStr = "cat /etc/*release | grep -E ^NAME";
  exec(cmdStr, function (err, stdout, stderr) {
    if (err) {
      res.send("command line execution error：" + err);
    }
    else {
      res.send(
        "Command line execution result：\n" +
          "Linux System:" +
          stdout +
          "\nRAM:" +
          os.totalmem() / 1000 / 1000 +
          "MB"
      );
    }
  });
});

//System permission read-only test
app.get("/test", function (req, res) {
  let cmdStr = 'mount | grep " / " | grep "(ro," >/dev/null';
  exec(cmdStr, function (error, stdout, stderr) {
    if (error !== null) {
      res.send("System permissions are --- non-read-only");
    } else {
      res.send("System permissions are --- read-only");
    }
  });
});

// keepalive begin
//web keep alive
function keep_web_alive() {
  // request home page, stay awake
  exec("curl -m8 " + url, function (err, stdout, stderr) {
    if (err) {
      console.log("Keep Alive - Request Home Page - Command Line Execution Error：" + err);
    }
    else {
      console.log("Keep alive-request ok:" + stdout);
    }
  });
}

setInterval(keep_web_alive, 300 * 1000);

app.use( /* For specific configuration item migration, see https://github.com/chimurai/http-proxy-middleware/blob/master/MIGRATION.md */
  legacyCreateProxyMiddleware({
    target: 'http://127.0.0.1:8080/', /* The address of the request that needs to be processed across domains */
    ws: true, /* Whether to proxy websocket */
    changeOrigin: true, /* Do you need to change the original host header to the target URL, default false */ 
    on: {  /* http proxy event set */ 
      proxyRes: function proxyRes(proxyRes, req, res) { /* Handle proxy requests */
        // console.log('RAW Response from the target', JSON.stringify(proxyRes.headers, true, 2)); //for debug
        // console.log(req) //for debug
        // console.log(res) //for debug
      },
      proxyReq: function proxyReq(proxyReq, req, res) { /* Handle proxy responses */
        // console.log(proxyReq); //for debug
        // console.log(req) //for debug
        // console.log(res) //for debug
      },
      error: function error(err, req, res) { /* handle exception  */
        console.warn('websocket error.', err);
      }
    },
    pathRewrite: {
      '^/': '/', /* Remove slashes from requests  */
    },
    // logger: console /* Whether to open the log  */
  })
);

//Start the core script to run web, Nezha and argo
exec("bash entrypoint.sh", function (err, stdout, stderr) {
  if (err) {
    console.error(err);
    return;
  }
  console.log(stdout);
});

app.listen(port, () => console.log(`Example app listening on port ${port}!`));