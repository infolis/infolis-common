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

JsonLdConnegMiddleware = (options) ->

	# <h3>Supported Types</h3>
	# The Middleware is able to output JSON-LD in these serializations

	typeMap = [
		['application/json',        'jsonld']   # no-op
		['application/ld+json',     'jsonld']   # no-op
		['application/rdf-triples', 'ntriples'] # jsonld/nquads -> raptor/ntriples
                                                # ['application/trig',        'trig']     # jsonld/nquads -> raptor/trig
		['text/vnd.graphviz',       'dot']      # jsonld/nquads -> rapper/graphviz
		['application/x-turtle',    'turtle']   # jsonld/nquads -> raptor/turtle
		['text/rdf+n3',             'turtle']   # jsonld/nquads -> raptor/turtle
		['text/turtle',             'turtle']   # jsonld/nquads -> raptor/turtle
		['application/rdf+json',    'json']     # jsonld/nquads -> raptor/json
		['application/nquads',      'nquads']   # jsonld/nquads
		['application/rdf+xml',     'rdfxml']   # jsonld/nquads -> raptor/rdfxml
		['text/xml',                'rdfxml']   # jsonld/nquads -> raptor/rdfxml
		['text/html',               'html']     # jsonld/nquads -> raptor/turtle -> jade
	]
	SUPPORTED_TYPES = {}
	SUPPORTED_TYPES[type] = shortType for [type, shortType] in typeMap

	# <h3>JSON-LD profiles</h3>
	JSONLD_PROFILE = 
		COMPACTED: 'http://www.w3.org/ns/json-ld#compacted'
		FLATTENED: 'http://www.w3.org/ns/json-ld#flattened'
		EXPANDED:  'http://www.w3.org/ns/json-ld#expanded'

	# <h3>Options</h3>
	options = options                         || {}
	# Context Link to be sent out as HTTP header (default: none)
	options.contextLink = options.contextLink || null
	# Context object (default: none)
	options.context = options.context         || {}
	# Base URI for RDF serializations that require them (i.e. all of them, hence the default)
	options.baseURI = options.baseURI         || 'http://NO-BASEURI-IS-SET.tld/'
	# Default JSON-LD compaction profile to use if no other profile is requested (defaults to compacted)
	options.profile = options.profile         || JSONLD_PROFILE.COMPACTED
	# Options for jsonld.expand
	options.expand = options.expand           || {expandContext: options.context}
	# Options for jsonld.compact
	options.compact =  options.compact        || {expandContext: options.context, compactArrays: true}
	# Options for jsonld.flatten
	options.flatten =  options.flatten        || {expandContext: options.context}

	# <h3>detectJsonLdProfile</h3>
	detectJsonLdProfile = (req) ->
		ret = options.profile
		acc = req.header('Accept')
		if acc
			requestedProfile = acc.match /profile=\"([^"]+)\"/
			if requestedProfile and requestedProfile[1]
				ret = requestedProfile[1]
		return ret

	_error = (statusCode, msg, cause) =>
		err = new Error (msg)
		err.statusCode = statusCode
		err.cause = cause
		return err

	handleJsonLd = (req, res, next) ->
		sendJsonLD = (err, body) ->
			if err
				return next _error(500,  "JSON-LD error restructuring error", err)
			res.statusCode = 200
			res.setHeader 'Content-Type', 'application/ld+json'
			return res.end JSON.stringify(body, null, 2)
		profile = detectJsonLdProfile(req)
		console.log profile
		console.log req.headers['accept']
		switch profile
			when JSONLD_PROFILE.COMPACTED
				return JsonLD.compact req.jsonld, options.context, options.compact, sendJsonLD
			when JSONLD_PROFILE.EXPANDED
				return JsonLD.expand req.jsonld, {expandContext: options.context}, sendJsonLD
			when JSONLD_PROFILE.FLATTENED
				return JsonLD.flatten req.jsonld, {expandContext: options.context}, sendJsonLD
			else
				return next _error(500, "Bad profile: #{profile}")

	# TODO Decide a proper output format for HTML -- prettified JSON-LD? Turtle?
	handleHtml = (req, res, next) ->
		res.statusCode = 200
		res.setHeader 'Content-Type', 'text/html'
		return res.send "<pre>" + JSON.stringify(req.jsonld) + '</pre>' # TODO

	# Need to convert JSON-LD to N-Quads
	handleRdf = (req, res, next) ->
		matchingType = Accepts(req).types(Object.keys SUPPORTED_TYPES)
		shortType = SUPPORTED_TYPES[matchingType]
		JsonLD.toRDF req.jsonld, {expandContext: options.context, format: "application/nquads"}, (err, nquads) ->
			if err
				return next new _error(500,  "Failed to convert JSON-LD to RDF", err)

			# If nquads were requested we're done now
			if shortType is 'nquads'
				res.statusCode = 200
				res.setHeader 'Content-Type', 'application/nquads'
				return res.send nquads

			# Spawn `rapper` with a nquads parser and a serializer producing `#{shortType}`
			cmd = "rapper -i nquads -o #{shortType} - #{options.baseURI}"
			serializer = ChildProcess.spawn("rapper", ["-i", "nquads", "-o", shortType, "-", options.baseURI])
			serializer.on 'error', (err) -> 
				return next _error(500, 'Could not spawn rapper process')
			# When data is available, concatenate it to a buffer
			buf=''
			errbuf=''
			serializer.stderr.on 'data', (chunk) -> 
				errbuf += chunk.toString('utf8')
			serializer.stdout.on 'data', (chunk) -> 
				buf += chunk.toString('utf8')
			# Pipe the nquads into the process and close stdin
			serializer.stdin.write(nquads)
			serializer.stdin.end()
			# When rapper finished without error, return the serialized RDF
			serializer.on 'close', (code) ->
				if code isnt 0
					return next _error(500,  "Rapper failed to convert N-QUADS to #{shortType}", errbuf)
				res.statusCode = 200
				res.setHeader 'Content-Type', matchingType
				res.send buf

	# <h3>handler</h3>
	# Return the actual middleware function
	handle = (req, res, next) ->

		###
		The JSON-LD must be attached as 'jsonld' to the request, i.e. the handler before the JSON-LD
		middleware must do
		```coffee
		_ handler : (req, res) ->
		_ 	# do something to create/retrieve jsonld
		_ 	req.jsonld = {'@context': ...}
		_ 	next()
		```
		###
		if not req.jsonld
			return next _error(500, 'No JSON-LD payload in the request, nothing to do')

		# To make qualified content negotiation, an 'Accept' header is required
		# TODO This is too strict and should be lifted before usage in production, i.e. just send JSON-LD
		if not req.header('Accept')
			return next _error(406,  "No Accept header given")

		matchingType = Accepts(req).types(Object.keys SUPPORTED_TYPES)

		if not SUPPORTED_TYPES[matchingType]
			return next _error(406, "Incompatible media type found for #{req.header 'Accept'}")

		switch SUPPORTED_TYPES[matchingType]
			when 'jsonld' then return handleJsonLd(req, res, next)
			when 'html'   then return   handleHtml(req, res, next)
			else               return    handleRdf(req, res, next)

	# Return
	return {
		handle: handle
		JSONLD_PROFILE: JSONLD_PROFILE
		SUPPORTED_TYPES: SUPPORTED_TYPES
	}

# ## Module exports	
module.exports = {
	NS: Namespaces
	RdfUtil: RdfUtil
	JsonLdConnegMiddleware: JsonLdConnegMiddleware
}

#ALT: test/middleware.coffee
