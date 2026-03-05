#!/usr/bin/env python

__author__ = "Adam Gautier"
__copyright__ = "Copyright 2022, All Rights Reserved"
__credits__ = ["Adam Gautier"]
__license__ = "None"
__version__ = "0.0.1"
__maintainer__ = "Adam Gautier"
__email__ = "adam@gautier.org"
__status__ = "Prototype"

from http.server import BaseHTTPRequestHandler, HTTPServer
import argparse
import datetime
import pathlib
import sys
import random
import requests
import yaml
import time
import logging

RESPONSE_HTML = """
<html>
 <head>
  <title>Blackhole Server</title>
 </head>
 <body>
  <h1>Blackhole Server</h1>
  <hr/>
  <h2>Default Test Page</h2>
 </body>
</html>
"""

TEST_PATH="/blackhole/test"
TEST_DOMAINS=[]
HEADER_HOST="Host"

logging.basicConfig(format="%(asctime)s %(name)s %(funcName)s %(levelno)s~%(message)s", level=logging.INFO)
logger = logging.getLogger("blackhole")

class Hosts:
    def __init__(self, config):
        self._last = 0
        self._config = None
        with open(config, "r") as file:
            data = file.read()
            self._config = yaml.safe_load(data)
        assert self._config is not None, "Configuration file(%s) not properly loaded" % config
        self._targets = self._config['targets']
        
    def lastUpdate(self, file):
        path = pathlib.Path(file)
        return path.stat()[8]
        
    def isUpdated(self):
        lists = self._config['files']
        wlu = self.lastUpdate(lists['white'])
        blu = self.lastUpdate(lists['black'])
        klu = self.lastUpdate(lists['block'])
        rtn = self._last <= wlu or self._last <= blu or (klu + 60) <= int(datetime.datetime.now().timestamp())
        self._last = int(datetime.datetime.now().timestamp())
        return rtn
       
    def _read_list(self, list):
        cache = []
        with open(list, "r") as file:
            for line in file.readlines():
                line = line.strip()
                if 0 < len(line) and '#' != line[0]: # Ignore comments
                    if " " in line:
                        logger.info("Invalid entry(%s)" % line)
                    else:
                        if line in cache:
                            logger.info("Duplicate host in %s: %s" % (list, line))
                        else:
                            cache.append(line)
        return cache
                        
    def _read_hosts(self, map):
        cache = {}
        with open(map, "r") as file:
            for line in file.readlines():
                line = line.strip()
                if 0 < len(line) and '#' != line[0]: # Ignore comments and blanks
                    tokens = line.split(" ")
                    if tokens[1] in cache.keys():
                        logger.info("Duplicate host in %s: %s" % (map, tokens[1]))
                    else:
                        cache[tokens[1]] = tokens[0]
        return cache
                        
    def _update_block_hosts(self):
        final = {}
        repos = self._config['repositories']
        for repo in repos:
            response = requests.get(repo)
            if 200 == response.status_code:
                logger.info("Fetched repository(%s) = %s" % (repo, response.status_code))
                lines = response.text.splitlines()
                for line in lines:
                    line = line.strip()
                    token = None
                    if 0 < len(line) and '#' != line[0]:
                        tokens = line.split()
                        if 1 == len(tokens):
                            token = tokens[0]
                        elif 2 == len(tokens):
                            token = tokens[1]
                    # assert token is not None, "Blacklist token cannot be nil."
                    if token is not None:
                        if token not in final.keys():
                            final[token] = []
                        final[token].append(repo)
        return final

    def _add_host(self, host):
        if host in self._blocked:
            logger.info("Host(%s) already loaded" % host)
            return
        if host in self._white:
            logger.info("Host(%s) is white listed" % host)
            return
        target = self._targets[random.randint(0, len(self._targets)-1)]
        if host in self._old:
            target = self._old[host]
        else:
            logger.info("Host(%s) is new" % host)
        self._blocked[host] = target
        
    def count(self):
        hosts = self._read_hosts(self._config['files']['block'])
        return len(hosts)
        
    def update(self, force=False):
        if not self.isUpdated() and not force:
            logger.info("No need to update hosts")
            return
            
        self._white = self._read_list(self._config['files']['white']) # [host]
        self._old = self._read_hosts(self._config['files']['block']) # {host:ip}
        
        self._blocked = {}
        
        black = self._read_list(self._config['files']['black']) # [host]
        for host in black:
            self._add_host(host)
        
        hosts = self._update_block_hosts() # {host:[src,...]}
        for host, src in hosts.items():
            self._add_host(host)
        
        with open(self._config['files']['block'], "w") as file:
            file.write("# %s\n" % len(self._blocked))
            for host, target in self._blocked.items():
                file.write("%s %s\n" % (target, host))
        logger.info("Total hosts: %s" % len(self._blocked))

            

class BlackHole(BaseHTTPRequestHandler):
        
    def do_DEFAULT(self, verb):
        print(file=sys.stderr)
        keys = self.headers.keys()
        for key in keys:
            logger.info("[H] %s: %s" % (key, self.headers.get(key)))

        host = ""
        if HEADER_HOST in keys:
            host = self.headers.get(HEADER_HOST)
            if ":" in host:
                host = host.split(":")[0]
                
        if host in TEST_DOMAINS:
            self.send_response (200)
            self.send_header("Content-type", "text/html")
            msg = RESPONSE_HTML
            if "/update" == self.path:
                msg = "<html><head><title></title><body><h1>UPDATE</h1><hr/><h2>UPDATE: %s</h2></body></html>"
                self.server.hosts.update(force=True)
                msg = msg % self.server.hosts.count()
            elif "/count" == self.path:
                msg = "<html><head><title></title><body><h1>Count</h1><hr/><h2>COUNT: %s</h2></body></html>"
                msg = msg % self.server.hosts.count()
            elif "/status" == self.path:
                pass
            elif "/health" == self.path:
                pass
            self.send_header("Content-length", len(msg))
            self.end_headers()
            self.wfile.write(bytes(msg, "utf8"))
            logger.info("Test: %s %s" % (verb, self.path))
            return
            
        if TEST_PATH == self.path:
            self.send_response (200)
            self.send_header("Content-type", "text/html")
            self.send_header("Content-length", len(RESPONSE_HTML))
            self.end_headers()
            self.wfile.write(bytes(RESPONSE_HTML, "utf8"))
            logger.info("Test: %s %s" % (verb, self.path))
            return
            
        if ("Host" in keys):
            logger.info("Request: %s %s %s" % (verb, self.headers.get("Host"), self.path))
        
        mime="text/html"
        if ("Accept" in keys):
            mimes = self.headers.get("Accept")
            mime = mimes.split(",")[0]
            
        encoding=None
        if ("Accept-Encoding" in keys):
            encodings = self.headers.get("Accept-Encoding")
            encoding = encodings.split(",")[0]
            
        self.send_response (200)
        self.send_header ("Content-type", mime)
        self.send_header("Content-length", 0)
        if encoding is not None:
            self.send_header("Content-Encoding", encoding)
        self.send_header("Connection", "close")
        self.end_headers ()
        if "HEAD" != verb:
            self.wfile.write(bytes("", "utf8"))
        

    def log_message(self, format, *args):
        pass
    
    def do_HEAD (self):
        logger.info("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! UNHANDLED HEAD")
        self.do_DEFAULT("HEAD")
        
    def do_POST (self):
        logger.info("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! UNHANDLED POST")
        self.do_DEFAULT("POST")
        
    def do_GET (self):
        self.do_DEFAULT("GET")

class BlackholeServer(HTTPServer):
    def __init__(self, server_address, RequestHandlerClass, configfile):
        self.__hosts = Hosts(configfile)
        self.__hosts.update()
        super().__init__(server_address, RequestHandlerClass)
        
    @property
    def hosts(self):
        return self.__hosts
    
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Blackhole Server - HTTP that returns valid but minimal null values.')
    parser.add_argument('--domains', default=None, help='Comma delimited list of fully qualified domain names that revert to testing responses')
    parser.add_argument('--host', default="0.0.0.0", help="Override the default host for the server to listen(0.0.0.0)")
    parser.add_argument('--port', default="8080", help="Override the default port for the server to listen(8080)")
    args = parser.parse_args()

    if args.domains is not None:
        TEST_DOMAINS = args.domains.split(",")
    #
    with BlackholeServer((args.host, int(args.port)), BlackHole, "/etc/container/hosts.yml") as server:
    # with HTTPServer ((args.host, int(args.port)), BlackHole) as server:
        for domain in TEST_DOMAINS:
            logger.info("Test domain(%s)" % domain)
        logger.info("Test path: %s" % TEST_PATH)
        logger.info("Blackhole Server listening: %s:%s" % (args.host, args.port))
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            logger.info("Blackhole Server shutdown")
