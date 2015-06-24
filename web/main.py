from urlparse import urlparse
from google.appengine.api import users
from google.appengine.ext import ndb
import os
import webapp2
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
        
        # If it is a request for an export pad, serve back a new pad with given data
        if path.endswith('newpad'):
            _serve(self.response, 'newpad', parsedURL.query)
            return

        if os.path.isfile(path):
            _serve(self.response, path)
            return

        # If it is a request for a file in the TLD, serve as is.
        if targetSplits[1].find('.') > 0:
            newPath = "/".join(targetSplits[1:])
            if newPath == '':
                _serve(self.response, mainPage)
            else:
                _serve(self.response, newPath, parsedURL.query)
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


# Return whether we're running in the development server or not.
def isDevelopment():
    return os.environ['SERVER_SOFTWARE'].startswith('Development')


# Serve the files.
def _serve(resp, path, query=''):
    print('path is '+path)
    if path.startswith('newpad'):
        queryFields = query.split('=')
        dart = queryFields[1].rstrip('html')[:-1]
        html = queryFields[2].rstrip('css')[:-1]
        css = queryFields[3]
        c = open('index.html', 'r').read()
        c = c + "<div id='dart-code'>{0}</div><div id='html-code'>{1}</div><div id='css-code'>{2}</div>".format(dart, html, css)
        resp.write(c)
        resp.content_type = 'text/html'
        return
        
    if path.startswith('embed-'):
        queryFields = query.split('style=')
        if queryField.length > 1:
            s = queryFields[1]
            c = open('index.html', 'r').read()
            if s == 'dark':
                c += "<link rel="stylesheet" href='embed_dark.css'>"
            elif s == 'light':
                c += "<link rel="stylesheet" href='embed_light.css'>"
            resp.write(c)
            resp.content_type = 'text/html'
            return
           
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
        resp.content_type = 'text/html '

    f = open(path, 'r')
    c = f.read()
    resp.write(c)
    return


app = webapp2.WSGIApplication([
    ('.*', MainHandler)
], debug=False)
