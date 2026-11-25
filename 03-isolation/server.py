import json
import os
import platform
import socket
from http.server import BaseHTTPRequestHandler, HTTPServer


def marker_readable():
    path = os.environ.get("MARKER")
    if not path:
        return False
    try:
        with open(path, "rb") as marker:
            marker.read(1)
            return True
    except OSError:
        return False


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        record = {"hostname": socket.gethostname(), "python": platform.python_version(),
                  "marker_readable": marker_readable()}
        body = json.dumps(record).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    address = (os.environ.get("HOST", "127.0.0.1"), int(os.environ.get("PORT", "8000")))
    HTTPServer(address, Handler).serve_forever()
