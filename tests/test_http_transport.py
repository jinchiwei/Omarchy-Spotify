import importlib.util,io,unittest,urllib.error
from pathlib import Path
from email.message import Message
spec=importlib.util.spec_from_file_location('transport',Path(__file__).resolve().parents[1]/'scripts/spotify-http.py')
transport=importlib.util.module_from_spec(spec);spec.loader.exec_module(transport)
class Response(io.BytesIO):
    code=200
    def __init__(self,body=b'{}',headers=None):
        super().__init__(body);self.headers=headers or Message()
class Opener:
    def __init__(self,response):self.response=response;self.request=None
    def open(self,request,timeout):
        self.request=request;self.timeout=timeout
        if isinstance(self.response,Exception):raise self.response
        return self.response
class TransportTests(unittest.TestCase):
    def test_get_preserves_authorization_without_logging(self):
        op=Opener(Response());result=transport.perform({'url':'https://api.spotify.com/v1/me','headers':{'Authorization':'Bearer private-test'}},op)
        self.assertEqual(result['status'],200);self.assertEqual(op.request.get_header('Authorization'),'Bearer private-test');self.assertEqual(op.timeout,10)
        self.assertNotIn('private-test',str(result))
    def test_oauth_post_uses_form_body(self):
        op=Opener(Response());transport.perform({'url':'https://accounts.spotify.com/api/token','method':'POST','body':'refresh_token=private-test','headers':{'Content-Type':'application/x-www-form-urlencoded'}},op)
        self.assertEqual(op.request.data,b'refresh_token=private-test');self.assertEqual(op.request.get_method(),'POST')
    def test_rejects_other_hosts_credentials_and_non_https(self):
        for url in ['http://api.spotify.com/v1/me','https://api.spotify.com.evil.test/v1/me','https://api.spotify.com@evil.test/v1/me','https://secret@api.spotify.com/v1/me','https://api.spotify.com:80/v1/me','https://accounts.spotify.com/not-token','https://api.spotify.com/v1/me#private']:
            with self.subTest(url=url),self.assertRaises(ValueError):transport.perform({'url':url},Opener(Response()))
    def test_http_failure_and_retry_after_are_preserved(self):
        headers=Message();headers['Retry-After']='120';headers['Set-Cookie']='private'
        op=Opener(urllib.error.HTTPError('https://api.spotify.com/v1/me',429,'busy',headers,io.BytesIO(b'{"error":"busy"}')))
        result=transport.perform({'url':'https://api.spotify.com/v1/me'},op)
        self.assertEqual(result['status'],429);self.assertEqual(result['headers'],{'retry-after':'120'})
    def test_redirects_are_not_followed(self):
        self.assertIsNone(transport.NoRedirect().redirect_request(None,None,302,None,None,'https://evil.test'))
    def test_response_size_is_bounded(self):
        with self.assertRaises(ValueError):transport.perform({'url':'https://api.spotify.com/v1/me'},Opener(Response(b'x'*(transport.MAX_BYTES+1))))
if __name__=='__main__':unittest.main()
