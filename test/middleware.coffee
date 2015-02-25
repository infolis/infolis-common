util = require 'util'
test = require 'tapes'
jsonLdMiddleware = require('../lib').JsonLdConnegMiddleware
{ ServerRequest, ServerResponse } =  require('mocks').http

req = new ServerRequest()
res = new ServerResponse()
mw = jsonLdMiddleware({})

req.headers.accept = 'application/ld+json'
req.jsonld = {
	'@context': {
		foaf:    "http://xmlns.com/foaf/0.1/"
	},
	'@id': 'urn:fake:kba'
	'foaf:firstName': 'Konstantin'
}
mw req, res, (err) ->
	console.log err

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
