from http.server import HTTPServer,SimpleHTTPRequestHandler

server_address = ('0.0.0.0', 80) # address 0.0.0.0 makes it listen to all requests from anywhere

class HTTPRequestHandler(SimpleHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        body = self.rfile.read(content_length)
        print(body.decode('utf-8')) #log display
        
        self.send_response(200)
        self.end_headers()
        
    def do_GET(self):
        print("D " + self.path) 
        SimpleHTTPRequestHandler.do_GET(self) #process using default do_GET
        
        

httpd = HTTPServer(server_address, HTTPRequestHandler)

httpd.serve_forever()