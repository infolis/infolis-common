util = require 'util'
test = require 'tapes'
express = require 'express'
request = require 'supertest'
jsonld = require 'jsonld'

JsonLdConnegMiddleware = require('../src').JsonLdConnegMiddleware

doc1 = {
	'@context': {
		"foaf": "http://xmlns.com/foaf/0.1/"
	},
	'@id': 'urn:fake:kba'
	'foaf:firstName': 'Konstantin'
}

# req = res = mw =app = null

setupExpress = (doc, mwOptions) ->
	mwOptions or= {}
	mw = JsonLdConnegMiddleware(mwOptions)
	app = express()
	app.get '/', (req, res, next) ->
		req.jsonld = doc 
		next()
	app.use mw.handle
	app.use (err, req, res, next) ->
		console.error {error: err}
		res.statusCode = err.statusCode
		res.end JSON.stringify({error: err }, null, 2)
	return [app, mw]

app = null
mw = JsonLdConnegMiddleware()
reApplicationJsonLd = new RegExp "application/ld\\+json"

testJSONLD = (t) ->
	t.beforeEach (t) ->
		[app, mw] = setupExpress(doc1)
		t.end()
	testProfile = (t, profile) ->
		t.test "Profile detection for #{profile}", (t) -> (request(app)
			.get('/')
			.set('Accept', "application/ld+json; q=1, profile=\"#{profile}\"") 
			.end (err, res) ->
				t.notOk err, 'No error'
				t.equals res.status, 200, 'Status 200'
				t.ok reApplicationJsonLd.test(res.headers['content-type']), 'Correct Type'
				switch profile
					when mw.JSONLD_PROFILE.COMPACTED
						jsonld.compact doc1, {}, (err, expanded) ->
							t.deepEquals JSON.parse(res.text), expanded, 'Correct profile is returned'
							t.end()
					when mw.JSONLD_PROFILE.FLATTENED
						jsonld.compact doc1, {}, (err, expanded) ->
							t.deepEquals JSON.parse(res.text), expanded, 'Correct profile is returned'
							t.end()
					when mw.JSONLD_PROFILE.EXPANDED
						jsonld.compact doc1, {}, (err, expanded) ->
							t.deepEquals JSON.parse(res.text), expanded, 'Correct profile is returned'
							t.end()
					else
						console.error("Unknown Profile -- WTF?")
						t.end()
		)
	testProfile(t, profile) for profileName, profile of mw.JSONLD_PROFILE
	t.end()

rdfTypes = [
	'text/turtle'
	'application/rdf-triples'
	# 'application/trig'
	'text/vnd.graphviz'
	'application/x-turtle'
	'text/rdf+n3'
	'application/rdf+json'
	'application/nquads'
	'application/rdf+xml'
	'text/xml'
]
testRDF = (t) ->
	t.beforeEach (t) ->
		[app, mw] = setupExpress(doc1)
		t.end()
	testFormat = (t, format) ->
		t.test "Testing #{format}", (t) ->
			request(app)
				.get('/')
				.set('Accept', format)
				.end (err, res) ->
					t.notOk err, 'No error'
					t.equals res.statusCode, 200, 'Returned yay'
					t.ok res.headers['content-type'].indexOf(format) > -1, 'GIGO'
					t.end()
	testFormat(t, rdfType) for rdfType in rdfTypes
	t.end()

test "JSON-LD", testJSONLD
# test "RDF", testRDF

		# req.headers.Accept = 'text/html'
		# res.on 'end', () ->
		#     console.log res
		#     # t.ok res._body
		#     # t.equals res.status, 200
		#     # t.deepEquals JSON.parse(res._body), req.jsonld, 'No change'
		#     # t.equals res.getHeader('Content-Type'), 'application/ld+json', 'content type correct'
		#     t.end()
		# mw req, res, (err) ->
		#     console.log err
		#     t.notOk err, 'No error'
	# t.end()

# test "Rapper", (t) ->
#     t.beforeEach (t) ->
#         req = mocks.createRequest()
#         res = mocks.createResponse()
#         mw = jsonLdMiddleware({})
#         req.jsonld = doc1
#         t.end()
#     t.test 'turtle', (t) ->
#         req.headers.accept = 'text/turtle'
#         mw req, res, (err) ->
#             t.notOk err, 'No error'
#         res.on 'end', () ->
#             t.ok res._body
#             t.equals res.status, 200
#             t.equals res.getHeader('Content-Type'), 'text/turtle', 'content type correct'
#             t.end()
#     t.end()

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
