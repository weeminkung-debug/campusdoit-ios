"""#97 앱 자동 갱신 시험 준비(5번방 #114): 시험 열쇠·새 버전 폴더·목록(정상·서명 틀림·내용 틀림)을 만든다.
쓰기: python3 tools/cdu_fixture.py <넣어 둔 화면 폴더(public)> <출력 폴더>  → 출력/pub.txt(공개 열쇠 b64)
목록 형식 = AppUpdate(swift·kt): {"body": b64(JSON{ver,files:[{p,h,u}]}), "sig": b64(DER ECDSA P-256 SHA-256)}"""
import sys,os,json,hashlib,base64,shutil,subprocess
pub_dir,out=sys.argv[1],sys.argv[2]
os.makedirs(out,exist_ok=True); k=os.path.join(out,'k.pem'); k2=os.path.join(out,'k2.pem')
for f in (k,k2): subprocess.run(['openssl','ecparam','-name','prime256v1','-genkey','-noout','-out',f],check=True)
der=subprocess.run(['openssl','ec','-in',k,'-pubout','-outform','DER'],check=True,capture_output=True).stdout
open(os.path.join(out,'pub.txt'),'w').write(base64.b64encode(der).decode())
V='v2'; vd=os.path.join(out,'srv',V); shutil.rmtree(vd,ignore_errors=True); shutil.copytree(pub_dir,vd)
ix=os.path.join(vd,'index.html'); s=open(ix,encoding='utf-8').read()
s=s.replace('<head>','<head><script>window.__CDUMARK="v2"</script>',1); open(ix,'w',encoding='utf-8').write(s)
files=[]
for r,_,fs in os.walk(vd):
    for f in fs:
        p=os.path.relpath(os.path.join(r,f),vd).replace(os.sep,'/')
        if not all(c.isalnum() or c in '_./-' for c in p) or '..' in p: continue
        files.append({'p':p,'h':hashlib.sha256(open(os.path.join(r,f),'rb').read()).hexdigest(),'u':'/'+V+'/'+p})
def env(body,key):
    bf=os.path.join(out,'body.json'); open(bf,'wb').write(body)
    sig=subprocess.run(['openssl','dgst','-sha256','-sign',key,bf],check=True,capture_output=True).stdout
    return json.dumps({'body':base64.b64encode(body).decode(),'sig':base64.b64encode(sig).decode()})
good=json.dumps({'ver':V,'files':files}).encode()
bad_files=[dict(f) for f in files]
for f in bad_files:
    if f['p']=='index.html': f['h']='0'*64
badhash=json.dumps({'ver':V,'files':bad_files}).encode()
for name,body,key in [('good',good,k),('badsig',good,k2),('badhash',badhash,k)]:
    d=os.path.join(out,'srv_'+name,'app'); os.makedirs(d,exist_ok=True); open(os.path.join(d,'manifest.json'),'w').write(env(body,key))
print('files',len(files),'pub',open(os.path.join(out,'pub.txt')).read()[:24]+'…')
