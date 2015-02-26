util = require 'util'
test = require 'tapes'
# jsonLdMiddleware = require('../lib').JsonLdConnegMiddleware
jsonLdMiddleware = require('../src').JsonLdConnegMiddleware
{ ServerRequest, ServerResponse } =  require('mocks').http

req = new ServerRequest()
res = new ServerResponse()
mw = jsonLdMiddleware({})

doc1 = {
	'@context': {
		"foaf": "http://xmlns.com/foaf/0.1/"
	},
	'@id': 'urn:fake:kba'
	'foaf:firstName': 'Konstantin'
}

test "JSON-LD", (t) ->
	t.beforeEach (t) ->
		req = new ServerRequest()
		res = new ServerResponse()
		mw = jsonLdMiddleware({})
		req.jsonld = doc1
		t.end()
	t.test 'default', (t) ->
		req.headers.accept = 'application/ld+json'
		res.on 'end', () ->
			t.ok res._body
			t.equals res.status, 200
			t.deepEquals JSON.parse(res._body), req.jsonld, 'No change'
			t.equals res.getHeader('Content-Type'), 'application/ld+json', 'content type correct'
			t.end()
		mw req, res, (err) ->
			t.notOk err, 'No error'
	t.end()

test "Rapper", (t) ->
	t.beforeEach (t) ->
		req = new ServerRequest()
		res = new ServerResponse()
		mw = jsonLdMiddleware({})
		req.jsonld = doc1
		t.end()
	t.test 'turtle', (t) ->
		req.headers.accept = 'text/turtle'
		mw req, res, (err) ->
			t.notOk err, 'No error'
		res.on 'end', () ->
			t.ok res._body
			t.equals res.status, 200
			t.equals res.getHeader('Content-Type'), 'text/turtle', 'content type correct'
			t.end()
	t.end()

# test 'ConNeg', (t) ->

#     req = res = mw = null

#     t.beforeEach (t) ->
#         req = new ServerRequest()
#         res = new ServerResponse()
#         mw = jsonLdMiddleware({})
#         t.end()

#     # t.test 'No JSON-LD provided', (t) ->
#     #     mw req, res, (err) ->
#     #         t.ok err
#     #         t.equals err.status, 500
#     #         t.equals err.message.indexOf("No JSON"), 0
#     #         t.end()

#     # t.test 'No Accept header', (t) ->
#     #     req.jsonld = {}
#     #     mw req, res, (err) ->
#     #         t.ok err
#     #         t.equals err.status, 406
#     #         t.equals err.message.indexOf("No Accept"), 0
#     #         t.end()

#     # t.test 'Incompatible media type', (t) ->
#     #     req.jsonld = {}
#     #     req.headers.accept = 'xxxx/foo/bar'
#     #     mw req, res, (err) ->
#     #         t.ok err
#     #         t.equals err.status, 406
#     #         t.equals err.message.indexOf("Incompatible"), 0
#     #         t.end()

#     t.test 'Get JSON-LD', (t) ->
#         req.jsonld = {foo: 42}
#         req.headers.accept = 'application/ld+json'
#         mw req, res, (err) ->
#             res.on 'finish', (err, foo) ->
#                 console.log err
#                 console.log foo
#                 t.end()
#             # return t.end()
#             # t.notOk err
#             # t.equals res.status, 200
#             # t.equals err.message, 200
#             t.end()

#     t.end()

# ALT: src/index.coffee
