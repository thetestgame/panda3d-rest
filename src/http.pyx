"""
Author: Jordan Maxwell
Written: 02/18/2019

The MIT License (MIT)

Copyright (c) 2019 Nxt Games

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""

from panda3d.core import HTTPClient, HTTPChannel, DocumentSpec
from panda3d.core import Ramfile, UniqueIdAllocator, ConfigVariableInt

import json

cdef class HTTPRest(object):
    """
    Primary class for handling GET/POST requests with Panda's HTTPClient object
    """

    cdef object _http_client
    cdef object _request_allocator
    cdef dict _requests

    def __cinit__(self):
        self._http_client = HTTPClient()

        max_http_requests = ConfigVariableInt('http-max-requests', 900).value
        self._request_allocator = UniqueIdAllocator(0, max_http_requests)
        self._requests = {}

    cpdef void update(self):
        """
        Performs update operations on the PandaHTTP instance
        """

        for request_id in list(self._requests):

            # Check that this id is still valid
            if request_id not in self._requests:
                continue

            request = self._requests[request_id]
            request.update()

    cpdef void destroy(self):
        """
        Performs destruction operations on the PandaHTTP instance
        """
    
        for request_id in list(self._requests):
            self.remove_request(request_id)

    cpdef void remove_request(self, request_id):
        """
        Removes the request id form the PandaHTTP request list
        """
        
        if request_id not in self._requests:
            return

        self._request_allocator.free(request_id)
        del self._requests[request_id]

    cpdef int get_request_status(self, request_id):
        """
        Returns the requests current status
        """

        return not request_id in self._requests

    cpdef HTTPRequest get_request(self, request_id):
        """
        Returns the requested request if its present
        """

        return self._requests.get(request_id, None)

    cpdef int perform_get_request(self, url, headers={}, content_type=None, callback=None):
        """
        Performs an HTTP restful GET call and returns the request's unique itentifier
        """

        _rest_notify.debug('Sending GET request: %s' % url)

        request_channel = self._http_client.make_channel(True)

        if content_type != None:
            request_channel.set_content_type(content_type)

        for header_key in headers:
            header_value = headers[header_key]
            request_channel.send_extra_header(header_key, header_value)

        request_channel.begin_get_document(DocumentSpec(url))

        ram_file = Ramfile()
        request_channel.download_to_ram(ram_file, False)

        request_id = self._request_allocator.allocate()
        http_request = HTTPRequest(self, request_id, request_channel, ram_file, callback)
        self._requests[request_id] = http_request

        return request_id

    def perform_json_get_request(self, url, headers={}, callback=None):
        """
        """

        def json_wrapper(data):
            """
            Wraps the callback to automatically perform json.load
            on the resulting data
            """

            try:
                data = json.loads(data)
            except:
                _rest_notify.warning('Received invalid JSON results: %s' % data)
                
            callback(data)

        return self.perform_get_request(
            url=url, 
            content_type='application/json',
            headers=headers,
            callback=json_wrapper)

    cpdef int perform_post_request(self, url, headers={}, content_type=None, post_body={}, callback=None):
        """
        """

        _rest_notify.debug('Sending POST request: %s' % url)

        request_channel = self._http_client.make_channel(True)

        if content_type != None:
            request_channel.set_content_type(content_type)

        for header_key in headers:
            header_value = headers[header_key]
            request_channel.send_extra_header(header_key, header_value)

        post_body = json.dumps(post_body)
        request_channel.begin_post_form(DocumentSpec(url), post_body)

        ram_file = Ramfile()
        request_channel.download_to_ram(ram_file, False)

        request_id = self._request_allocator.allocate()
        http_request = HTTPRequest(self, request_id, request_channel, ram_file, callback)
        self._requests[request_id] = http_request

        return request_id

    def perform_json_post_request(self, url, headers={}, post_body={}, callback=None):
        """
        """

        def json_wrapper(data):
            """
            Wraps the callback to automatically perform json.load
            on the resulting data
            """

            try:
                data = json.loads(data)
            except:
                _rest_notify.warning('Received invalid JSON results: %s' % data)

            callback(data)

        return self.perform_post_request(
            url=url, 
            content_type='application/json',
            headers=headers,
            post_body=post_body, 
            callback=json_wrapper)