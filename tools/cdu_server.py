"""#97 시험 서버: python3 tools/cdu_server.py <포트> <목록 폴더(srv_good 등)> <파일 폴더(srv)> [drop]
drop = 목록은 주고 파일 받기 도중 연결을 끊음(끊김 시험)"""
import sys,os,http.server,socketserver
port,mdir,fdir=int(sys.argv[1]),sys.argv[2],sys.argv[3]; drop=len(sys.argv)>4 and sys.argv[4]=='drop'
class H(http.server.BaseHTTPRequestHandler):
    def log_message(self,*a): pass
    def do_GET(self):
        p=self.path.split('?')[0]
        f=os.path.join(mdir,p.lstrip('/')) if p.startswith('/app/') else os.path.join(fdir,p.lstrip('/'))
        if not os.path.isfile(f): self.send_response(404); self.end_headers(); return
        d=open(f,'rb').read()
        self.send_response(200); self.send_header('Content-Length',str(len(d))); self.end_headers()
        if drop and not p.startswith('/app/'):
            self.wfile.write(d[:max(1,len(d)//3)]); self.wfile.flush(); self.connection.shutdown(2); return
        self.wfile.write(d)
class S(socketserver.ThreadingMixIn,http.server.HTTPServer): daemon_threads=True; allow_reuse_address=True
S(('0.0.0.0',port),H).serve_forever()
