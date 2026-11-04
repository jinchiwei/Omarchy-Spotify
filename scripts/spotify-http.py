#!/usr/bin/env python3
"""One bounded Spotify HTTP request. Credentials enter via stdin, never argv/logs."""
import json,sys,urllib.request,urllib.error,urllib.parse
MAX_BYTES=8*1024*1024
class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self,*args,**kwargs):
        return None

def perform(payload,opener=None):
    url=urllib.parse.urlsplit(str(payload.get('url','')))
    method=str(payload.get('method','GET')).upper()
    valid=(url.scheme=='https' and url.port in (None,443) and not url.username and not url.password
           and not url.fragment and method in ('GET','POST','PUT','DELETE','PATCH'))
    valid=valid and ((url.hostname=='api.spotify.com' and url.path.startswith('/v1/'))
                    or (url.hostname=='accounts.spotify.com' and url.path=='/api/token' and method=='POST'))
    if not valid:raise ValueError('Unsupported request')
    headers=payload.get('headers') or {}
    if not isinstance(headers,dict):raise ValueError('Invalid headers')
    body=payload.get('body');data=None if body is None else str(body).encode('utf-8')
    request=urllib.request.Request(url.geturl(),data=data,headers=headers,method=method)
    opener=opener or urllib.request.build_opener(NoRedirect())
    try: response=opener.open(request,timeout=10)
    except urllib.error.HTTPError as error: response=error
    with response:
        raw=response.read(MAX_BYTES+1)
        if len(raw)>MAX_BYTES:raise ValueError('Response too large')
        return {'status':response.code,'body':raw.decode('utf-8',errors='replace'),
                'headers':{k.lower():v for k,v in response.headers.items() if k.lower() in ('retry-after','content-type')}}

def main():
    try:
        raw=sys.stdin.buffer.readline(MAX_BYTES+1)
        if len(raw)>MAX_BYTES:raise ValueError('Request too large')
        result=perform(json.loads(raw))
    except Exception:
        # Exception text can include private URLs/headers. Do not emit it.
        result={'status':0,'body':'','headers':{}}
    sys.stdout.write(json.dumps(result));sys.stdout.flush()
if __name__=='__main__':main()
