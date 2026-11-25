import json
import os
import argparse
from http.server import BaseHTTPRequestHandler, HTTPServer


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        record = {"version": args.app_version}
        body = json.dumps(record).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--app-version", required=True)
    parser.add_argument("--version", action="store_true")
    args = parser.parse_args()
    if args.version:
        print(args.app_version)
        raise SystemExit(0)
    address = (os.environ.get("HOST", "127.0.0.1"), int(os.environ.get("PORT", "8000")))
    HTTPServer(address, Handler).serve_forever()
