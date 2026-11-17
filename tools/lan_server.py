"""Telefon ve demo için yerel ağ sunucusu.

Derlenmiş web uygulamasını (see_it_on/build/web) sunar, /api/* ve /health isteklerini
backend'e (127.0.0.1:8001) aktarır. Uygulama ile backend aynı adreste göründüğü için tarayıcı
istekleri engellemez ve telefonda tek bir adres açmak yeter.

  http://<IP>:8000   Android uygulaması (APK) ve kamerasız denemeler
  https://<IP>:8443  iPhone Safari: kamera yalnızca güvenli bağlamda (HTTPS) açılır.
                     Sertifika kendi imzalıdır; telefonda uyarı bir kez kabul edilir.

Kullanım: python tools/lan_server.py [--web see_it_on/build/web] [--cert C --key K]
--cert/--key verilmezse yalnızca HTTP açılır.
"""
import argparse
import http.client
import mimetypes
import os
import ssl
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
BACKEND = ("127.0.0.1", 8001)
API_PREFIXES = ("/api/", "/health", "/docs", "/openapi")
HOP = {"connection", "keep-alive", "transfer-encoding", "upgrade", "proxy-connection", "te", "trailer"}

mimetypes.add_type("application/javascript", ".mjs")
mimetypes.add_type("application/wasm", ".wasm")
mimetypes.add_type("application/vnd.android.package-archive", ".apk")


def make_handler(web_root):
    class Handler(BaseHTTPRequestHandler):
        protocol_version = "HTTP/1.1"

        def _static(self):
            rel = self.path.split("?", 1)[0].lstrip("/") or "index.html"
            path = os.path.abspath(os.path.join(web_root, rel))
            # Dizin dışına çıkan yollar ve bilinmeyen adresler uygulamanın ana sayfasına düşer
            if not path.startswith(web_root + os.sep) or not os.path.isfile(path):
                path = os.path.join(web_root, "index.html")
            with open(path, "rb") as f:
                data = f.read()
            self.send_response(200)
            self.send_header("Content-Type", mimetypes.guess_type(path)[0] or "application/octet-stream")
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-cache")
            self.end_headers()
            if self.command != "HEAD":
                self.wfile.write(data)

        def _forward(self):
            is_api = self.path.startswith(API_PREFIXES)
            if not is_api:
                if self.command in ("GET", "HEAD"):
                    return self._static()
                self.send_error(405)
                return
            length = int(self.headers.get("Content-Length") or 0)
            body = self.rfile.read(length) if length else None
            headers = {k: v for k, v in self.headers.items() if k.lower() not in HOP and k.lower() != "host"}
            headers["Host"] = f"{BACKEND[0]}:{BACKEND[1]}"
            conn = http.client.HTTPConnection(*BACKEND, timeout=600)
            try:
                conn.request(self.command, self.path, body=body, headers=headers)
                resp = conn.getresponse()
                data = resp.read()
            except Exception as e:
                self.send_error(502, f"Backend yanit vermedi: {e}")
                return
            finally:
                conn.close()
            self.send_response(resp.status, resp.reason)
            for k, v in resp.getheaders():
                if k.lower() not in HOP and k.lower() != "content-length":
                    self.send_header(k, v)
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        do_GET = do_POST = do_DELETE = do_PUT = do_OPTIONS = do_HEAD = _forward

        def log_message(self, fmt, *args):
            pass

    return Handler


def serve(port, handler, tls=None):
    ThreadingHTTPServer.allow_reuse_address = False  # Windows'ta aynı portu ikinci sürecin almasını engeller
    httpd = ThreadingHTTPServer(("0.0.0.0", port), handler)
    if tls:
        ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        ctx.load_cert_chain(*tls)
        httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True)
    return httpd


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--web", default=os.path.join(ROOT, "see_it_on", "build", "web"))
    ap.add_argument("--port", type=int, default=8000)
    ap.add_argument("--tls-port", type=int, default=8443)
    ap.add_argument("--cert")
    ap.add_argument("--key")
    args = ap.parse_args()

    web_root = os.path.abspath(args.web)
    if not os.path.isfile(os.path.join(web_root, "index.html")):
        raise SystemExit(f"Web uygulaması bulunamadı: {web_root} (önce: flutter build web --release)")
    handler = make_handler(web_root)

    servers = [serve(args.port, handler)]
    print(f"HTTP : http://<IP>:{args.port}   (Android uygulaması, kamerasız denemeler)", flush=True)
    if args.cert and args.key:
        servers.append(serve(args.tls_port, handler, (args.cert, args.key)))
        print(f"HTTPS: https://<IP>:{args.tls_port}  (iPhone Safari, kamera)", flush=True)
    print(f"Backend: http://{BACKEND[0]}:{BACKEND[1]}  Web: {web_root}", flush=True)

    for s in servers[1:]:
        threading.Thread(target=s.serve_forever, daemon=True).start()
    servers[0].serve_forever()


if __name__ == "__main__":
    main()
