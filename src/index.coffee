# # infolis-common

JsonLD       = require 'jsonld'
N3           = require 'n3'
Async        = require 'async'
Accepts      = require 'accepts'
ChildProcess = require 'child_process'

# ## Namespaces
###

Lists the namespaces and outputs them in different serializations.

TODO: Decide how to handle versioned namespaces like `prism`

###

Namespaces =

	# ### Namespace definitions
	adms:    'http://www.w3.org/ns/adms#'
	bibo:    "http://purl.org/ontology/bibo/"
	dcat:    'http://www.w3.org/ns/dcat#'
	dc:      'http://purl.org/dc/elements/1.1/'
	dcterms: 'http://purl.org/dc/terms/'
	disco:   'http://rdf-vocabulary.ddialliance.org/discovery#'
	foaf:    'http://xmlns.com/foaf/0.1/'
	foaf:    "http://xmlns.com/foaf/0.1/"
	infolis: "http://www-test.bib.uni-mannheim.de/infolis/dev/vocab/"
	org:     'http://www.w3.org/ns/org#'
	owl:     'http://www.w3.org/2002/07/owl#'
	prov:    'http://www.w3.org/ns/prov#'
	qb:      'http://purl.org/linked-data/cube#'
	rdf:     'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
	rdf:     'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
	rdfs:    'http://www.w3.org/2000/01/rdf-schema#'
	rdfs:    "http://www.w3.org/2000/01/rdf-schema#"
	schema:  "http://schema.org/"
	skos:    'http://www.w3.org/2004/02/skos/core#'
	xkos:    'http://purl.org/linked-data/xkos#'
	xsd:     'http://www.w3.org/2001/XMLSchema#'
	prism:   "http://prismstandard.org/namespaces/basic/2.1/"

	# ### toJSON()
	###
	
	Output the namespaces as they are
	###
	toJSON: () ->
		ret = {}
		for k,v of @
			if not (~k.indexOf('_') or ~k.indexOf('to'))
				ret[k] = v
		return ret

	# ### toJSONLD()
	###
	
	Output the namespaces in a JSON-LD compatible way, e.g.:
	```
	"@context": {
		"schema": {"@id": "http://schema.org"}
	}
	```
	###
	toJSONLD: () ->
		ret = {'@context': {}}
		for k,v of @toJSON()
			ret['@context'][k] = {'@id': v}
		return ret

	# ### toTurtle()
	###
	
	Output the namespaces in the Turtle format

	###
	toTurtle: () ->
		lines = []
		for k,v of @toJSON()
			lines.push "@prefix #{k}: <#{v}>."
		return lines.join("\n")


# ## RdfUtil
###

Wraps the N3 triple parser/emitter in calls that wrap the streaming
functionality and provide the final result to a callback.
###

RdfUtil =

	# ### writeN3Sync
	###
	
	TODO
	
	@param {object} triples	Triples to write out
	@param {object} opts	Options to pass on to n3.Writer
	@param {function} callback	Callback to call on finish
	###
	writeN3Sync: (triples, opts, callback) ->
		if not opts or not callback
			callback "Must pass 'opts' and 'callback' to writeN3Sync"
		n3Writer = N3.Writer(opts)
		for t in triples
			n3Writer.addTriple t
		n3Writer.end (err, data) ->
			# `callback(err, data)`: `err` will be null on success, `data` is the written RDF
			if err and err isnt {}
				callback err, data
			else
				callback null, data

	# ### parseN3Sync
	###
	
	TODO
	
	@param {object} data	String to parse as Triples
	@param {function} callback	Callback to call on parsed triples
	###
	parseN3Sync: (data, callback) ->
		n3Parser = N3.Parser()
		triples = []
		doneParsing = false
		Async.until(
			# Condition callback
			() -> doneParsing
			# Loop Body
			(doneParsingCallback) ->
				n3Parser.parse data, (errN3Parser, triple) ->
					if errN3Parser
						doneParsing = true
						return doneParsingCallback(errN3Parser)
					else if not triple
						doneParsing = true
						return doneParsingCallback()
					else
						return triples.push triple
			# On completion
			# `callback(err, data)`: `err` will be null on success, `data` is the parsed RDF
			(err) -> callback err, triples
		)

	# ### convertN3Sync
	###
	
	TODO
	
	Combines [#parseN3Sync]() and [#writeN3Sync]().

	###
	convertN3Sync: (data, opts, callback) ->
		# Pipe data through function calls
		Async.waterfall([
			(next) =>
				@parseN3Sync data, (errParse, triples) =>
					return next errParse if errParse
					return next null, triples
			(triples, next) =>
				@writeN3Sync triples, opts, (errWrite, result) ->
					if errWrite
						return next errWrite
					return next null, result
			],
			# `callback(err, data)`: `err` will be null on success, `data` is the written RDF
			callback
		)

	convertWithRaptor: (data, outFormat, callback) ->
		serializer = raptor.createSerializer('outFormat')


# ## JsonLdConnegMiddleware
###

Middleware for Express/Connect that handles Content-Negotiation and sends the
right format to the client, based on the JSON-LD representation of the graph.

###

supportedTypes = {
	'application/json':        'jsonld'   # no-op
	'application/ld+json':     'jsonld'   # no-op
	'application/rdf-triples': 'ntriples' # jsonld/nquads -> raptor/ntriples
	'application/trig':        'trig'     # jsonld/nquads -> raptor/trig
	'application/x-turtle':    'turtle'   # jsonld/nquads -> raptor/turtle
	'text/rdf+n3':             'turtle'   # jsonld/nquads -> raptor/turtle
	'text/turtle':             'turtle'   # jsonld/nquads -> raptor/turtle
	'application/rdf+json':    'rdfjson'  # jsonld/nquads -> raptor/json
	'application/nquads':      'nquads'   # jsonld/nquads
	'application/rdf+xml':     'rdfxml'   # jsonld/nquads -> raptor/rdfxml
	'text/xml':                'rdfxml'   # jsonld/nquads -> raptor/rdfxml
	'text/html':               'html'     # jsonld/nquads -> raptor/turtle -> jade
}
JsonLdConnegMiddleware = (options) ->
	options = options || {}
	context = options.context || {}
	baseURI = options.baseURI || 'http://NO-BASEURI-IS-SET.tld/'
	# TODO provide options for prefixes, baseURI etc pp
	return (req, res, next) ->
		if not req.jsonld
			return next { status: 500, message: 'No JSON-LD payload in the request, nothing to do' }

		if not req.headers.accept
			return next { status: 406,  message: "No Accept header given" }

		acc = Accepts(req)
		matchingType = acc.types(Object.keys(supportedTypes))

		if not supportedTypes[matchingType]
			return next { status: 406,  message: "Incompatible media type found for #{req.getHeader 'Accept'}" }

		shortType = supportedTypes[matchingType]
		switch supportedTypes[matchingType]
			when 'jsonld'
				# Nothing to do, data is already in the right format'
				res.status = 200
				res.setHeader 'Content-Type', 'application/ld+json'
				return res.send JSON.stringify(req.jsonld, null, 2)
			when 'html'
				# TODO decide what to do here actually
				res.status = 200
				res.setHeader 'Content-Type', 'text/html'
				return res.send "<pre>" + JSON.stringify(req.jsonld) + '</pre>' # TODO
			else
				JsonLD.toRDF req.jsonld, {expandContext: context, format: "application/nquads"}, (err, nquads) ->
					if err
						return next { status: 500,  message: "Failed to convert JSON-LD to RDF", body: err }
					# If nquads were requested we're done now
					if matchingType is 'nquads'
						res.status = 200
						res.setHeader 'Content-Type', 'application/nquads'
						return res.send nquads
					cmd = "rapper -i nquads -o #{shortType} - #{baseURI}"
					buf=''
					serializer = ChildProcess.spawn("rapper", ["-i", "nquads", "-o", shortType, "-", baseURI])
					serializer.on 'error', (err) -> console.error err
					serializer.stdout.on 'data', (chunk) -> 
						buf += chunk.toString('utf8')
					serializer.stdin.write(nquads)
					serializer.stdin.end()
					serializer.on 'close', (code) ->
						if code isnt 0
							return next { status: 500,  message: "Rapper failed to convert N-QUADS to #{shortType}", body: err }
						res.status = 200
						res.setHeader 'Content-Type', matchingType
						res.send buf



# ## Module exports	
module.exports = {
	NS: Namespaces
	RdfUtil: RdfUtil
	JsonLdConnegMiddleware: JsonLdConnegMiddleware
}

#ALT: test/middleware.coffee
