# -*- coding: utf-8 -*-

#   __
#  /__)  _  _     _   _ _/   _
# / (   (- (/ (/ (- _)  /  _)
#          /

"""
requests HTTP library
~~~~~~~~~~~~~~~~~~~~~

Requests is an HTTP library, written in Python, for human beings. Basic GET
usage:

   >>> import requests
   >>> r = requests.get('https://www.python.org')
   >>> r.status_code
   200
   >>> 'Python is a programming language' in r.content
   True

... or POST:

   >>> payload = dict(key1='value1', key2='value2')
   >>> r = requests.post('http://httpbin.org/post', data=payload)
   >>> print(r.text)
   {
     ...
     "form": {
       "key2": "value2",
       "key1": "value1"
     },
     ...
   }

The other HTTP methods are supported - see `requests.api`. Full documentation
is at <http://python-requests.org>.

:copyright: (c) 2014 by Kenneth Reitz.
:license: Apache 2.0, see LICENSE for more details.

"""

__title__ = 'requests'
__version__ = '2.4.3'
__build__ = 0x020403
__author__ = 'Kenneth Reitz'
__license__ = 'Apache 2.0'
__copyright__ = 'Copyright 2014 Kenneth Reitz'

# On Debian make Python import system know that requests.packages.urllib3
# and urllib3 are the same thing.
import pkgutil
import sys
import urllib3

def _attach_namespace(package, where):
    # Attach package top namespace
    sys.modules[where + '.' + package.__name__] = package
    for loader, name, ispkg in pkgutil.walk_packages(package.__path__,
                                                     package.__name__ + '.'):
        try:
            module = __import__(name)
        except ImportError:
            continue
        sys.modules[where + '.' + name] = module

_attach_namespace(urllib3, 'requests.packages')
del _attach_namespace
# Python 3 needs this imported explicitly.
import requests.packages

# Attempt to enable urllib3's SNI support, if possible
try:
    from urllib3.contrib import pyopenssl
    pyopenssl.inject_into_urllib3()
except ImportError:
    pass

from . import utils
from .models import Request, Response, PreparedRequest
from .api import request, get, head, post, patch, put, delete, options
from .sessions import session, Session
from .status_codes import codes
from .exceptions import (
    RequestException, Timeout, URLRequired,
    TooManyRedirects, HTTPError, ConnectionError
)

# Set default logging handler to avoid "No handler found" warnings.
import logging
try:  # Python 2.7+
    from logging import NullHandler
except ImportError:
    class NullHandler(logging.Handler):
        def emit(self, record):
            pass

logging.getLogger(__name__).addHandler(NullHandler())
