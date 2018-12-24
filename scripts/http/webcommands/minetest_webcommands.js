// listen to web request and pass it to minetest or back to web, rnd 2018

// INSTRUCTIONS. url options:
// 1./mtmsg/msg will store msg as message received from minetest ( minetest_message). note that msg cant contain spaces or newlines
// 2./getwebmsg/ will reply = IP + ' ' + webmessage
// 3./webmsg/msg will store message as webmessage
// 4./getmtmsg will reply with minetest_message


// NOTES: 1. avoids the need to deal with POST nastyness and complications like 
// https://stackoverflow.com/questions/4295782/how-do-you-extract-post-data-in-node-js

const http = require('http');


const hostname = '192.168.0.10' //write address of your router (it will be accessible from internet then if you open firewall for nodejs process)
const port = 80;

var webreq = "" // message from web
var mtreq = ""  // message from mt

// take request from web and pass it to minetest 
const server = http.createServer((req, res) => {
	res.statusCode = 200;
	res.setHeader('Content-Type', 'text/plain');

	var msg = req.url;
	if (msg == '/favicon.ico') return // prevent passing this as request
	
	
	var pos = msg.indexOf("/",1);  // gets the 2nd / in /part1/part2/...
	var cmd = msg.substring(1,pos);
	var response = ""
	var ip = req.connection.remoteAddress;
	
	switch(cmd)
	{
		case "mtmsg":
			response = msg.substring(pos+1);
			mtreq = response
			break
		case "getmtmsg":
			response = mtreq; mtreq = ''
			break
		case "getwebmsg":
			response = webreq; webreq = ''
			break
		case "webmsg":
			webreq = ip + ' ' + msg.substring(pos+1);
			response = 'request received: ' + webreq + '\nuse /getmtmsg to view response from minetest'
			break
		default:
			response = 'INSTRUCTIONS. url options:\n'+
				'1./mtmsg/msg will store msg as message received from minetest ( minetest_message). note that msg cant contain spaces or newlines\n'+
				'2./getwebmsg/ will reply = IP + " " + webmessage\n'+
				'3./webmsg/msg will store message as webmessage\n'+
				'4./getmtmsg will reply with minetest_message\n'
	}
	
	if (msg!='' && cmd != 'getwebmsg') console.log('ip ' + ip + ', msg ' + msg)
	res.write(response); res.end()
	return
});

// make server listen
server.listen(port, hostname, () => {
  console.log(`Server running at http://${hostname}:${port}/`);
});