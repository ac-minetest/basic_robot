// listen to web request and pass it to minetest, rnd 2018

const http = require('http');

const hostname = '192.168.0.10' //write address of your router (it will be accessible from internet then if you open firewall for nodejs process)
const port = 80;

var webreq = ""

// take request from web and pass it to minetest 
const server = http.createServer((req, res) => {
	res.statusCode = 200;
	res.setHeader('Content-Type', 'text/plain');

	if (req.url == '/favicon.ico') return // prevent passing this as request

	var pos = (req.url).indexOf("/MT"); 
	if (pos >=0) { // did request come from minetest? then answer with latest request
		res.write(webreq);webreq = "";res.end();return
	}

	//process web request and store it
	var ip = req.connection.remoteAddress;
	webreq = ip + ' ' + req.url
	res.write('request received: ' + webreq);res.end(); // acknowledge request
	return
});

server.listen(port, hostname, () => {
  console.log(`Server running at http://${hostname}:${port}/`);
});