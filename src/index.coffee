# # infolis-common

N3 = require 'n3'
Async = require 'async'

# ## Namespaces
###

Lists the namespaces and outputs them in different serializations.

TODO: Decide how to handle versioned namespaces like `prism`

###

Namespaces =

	# ### Namespace definitions
	adms: 'http://www.w3.org/ns/adms#'
	bibo: "http://purl.org/ontology/bibo/"
	dcat: 'http://www.w3.org/ns/dcat#'
	dc: 'http://purl.org/dc/elements/1.1/'
	dcterms: 'http://purl.org/dc/terms/'
	disco: 'http://rdf-vocabulary.ddialliance.org/discovery#'
	foaf: 'http://xmlns.com/foaf/0.1/'
	foaf: "http://xmlns.com/foaf/0.1/"
	infolis: "http://www-test.bib.uni-mannheim.de/infolis/dev/vocab/"
	org: 'http://www.w3.org/ns/org#'
	owl: 'http://www.w3.org/2002/07/owl#'
	prov: 'http://www.w3.org/ns/prov#'
	qb: 'http://purl.org/linked-data/cube#'
	rdf: 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
	rdf: 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
	rdfs: 'http://www.w3.org/2000/01/rdf-schema#'
	rdfs: "http://www.w3.org/2000/01/rdf-schema#"
	schema: "http://schema.org/"
	skos: 'http://www.w3.org/2004/02/skos/core#'
	xkos: 'http://purl.org/linked-data/xkos#'
	xsd: 'http://www.w3.org/2001/XMLSchema#'
	prism: "http://prismstandard.org/namespaces/basic/2.1/"

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

# ## Module exports	
module.exports =
	NS: Namespaces
	RdfUtil: RdfUtil
