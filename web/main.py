from urlparse import urlparse
from google.appengine.api import users
from google.appengine.ext import ndb
from google.appengine.ext import db

import os
import webapp2
import json

from mdetect import UAgentInfo

class WhiteListEntry(ndb.Model):
    emailAddress = ndb.StringProperty()


class MainHandler(webapp2.RequestHandler):
    def get(self):
        uagent = UAgentInfo(str(self.request.user_agent), str(self.request.accept))
        isMobile = uagent.detectMobileLong() or uagent.detectTierTablet()
        mainPage = 'mobile.html' if isMobile else 'index.html'

        if self.request.uri.find("try.dartlang.org") > 0:
            self.redirect("https://dartpad.dartlang.org")

        parsedURL = urlparse(self.request.uri)
        path = parsedURL.path;
        targetSplits = path.split('/')

        if os.path.isfile(path):
            _serve(self.response, path)
            return

        # If it is a request for a file in the TLD, serve as is.
        if targetSplits[1].find('.') > 0:
            newPath = "/".join(targetSplits[1:])
            if newPath == '':
                _serve(self.response, mainPage)
            else:
                _serve(self.response, newPath)
            return

        # If it is a request for a TLD psuedo-item, serve back the main page
        if len(targetSplits) < 3:
            _serve(self.response, mainPage)
            return

        # If it is a request for something in the packages folder, serve it
        if targetSplits[1] == 'packages':
            newPath = "/".join(targetSplits[1:])
            if newPath == '':
                _serve(self.response, mainPage)
            else:
                _serve(self.response, newPath)
            return

        # Otherwise it's a request for a item after the gist psudeo path
        # drop the gist and serve it.
        if len(targetSplits) >= 3:
            newPath = "/".join(targetSplits[2:])
            if newPath == '':
                _serve(self.response, mainPage)
            else:
                _serve(self.response, newPath)
            return

class Export(db.Model):
  dart = db.StringProperty()
  html = db.StringProperty()
  css = db.StringProperty()
  
class ExportHandler(webapp2.RequestHandler):
    def get(self):
        param=self.request.query_string;
        e = Export.all()
        e.filter('__key__ >', param)
        ds = e.run(limit=1)[0]
        _exportServe(self.response, ds)
        return  
    def post(self):
    	#obj = json.loads(self.request)
    	obj = self.request
    	print('method')
    	print(obj.method)
    	print('body')
    	print(obj.body)
    	print('post')
    	print(obj.POST)
    	print(type(obj.POST))
    	print(obj.POST['dart'])
        dartC = obj.POST['dart']
        htmlC = obj.POST['html']
        cssC = obj.POST['css']
        export = Export(dart=dartC, html=htmlC, css=cssC)
        export.dart = dartC
        export.html = htmlC
        export.css = cssC
        export.put()
        query_params = export.key_name();
        self.redirect('/export?' + query_params)
        return
        
def _exportServe(resp, ds):
    resp.content_type = 'text/html'
    f = open('index.html', 'r')
    c = f.read()
    c += "<div id='_dart'>{0}</div><div id='_html'>{1}</div><div id='_css'>{2}</div>".format(ds.dart,ds.html,ds.css)
    resp.write(c)
    return
    
# Return whether we're running in the development server or not.
def isDevelopment():
    return os.environ['SERVER_SOFTWARE'].startswith('Development')


# Serve the files.
def _serve(resp, path):
        
    if not os.path.isfile(path):
        resp.status = 404
        resp.write("<html><h1>404: Not found</h1></html>")
        return

    if path.endswith('.css'):
        resp.content_type = 'text/css'
    if path.endswith('.svg'):
        resp.content_type = 'image/svg+xml'
    if path.endswith('.js'):
        resp.content_type = 'application/javascript'
    if path.endswith('.ico'):
        resp.content_type = 'image/x-icon'
    if path.endswith('.html'):
        resp.content_type = 'text/html'

    f = open(path, 'r')
    c = f.read()
    resp.write(c)
    return


app = webapp2.WSGIApplication([
    ('/export', ExportHandler),
    ('.*', MainHandler)
], debug=False)
