test = require 'tape'
utils = require '../src'

test 'Sanity check', (t) ->
	t.ok utils, "Module loads"
	t.ok utils.NS, "Namespaces load"
	t.ok utils.RdfUtil, "RdfUtil loads"
	t.end()

test 'Namespace export', (t) ->
	expect = 19
	toJSON = utils.NS.toJSON()
	toJSONLD = utils.NS.toJSONLD()
	toTurtle = utils.NS.toTurtle()
	t.equals Object.keys(toJSON).length, expect, "All returned in JSON"
	t.equals Object.keys(toJSONLD['@context']).length, expect, "All returned in JSON-LD"
	t.equals toTurtle.split("\n").length, expect, "All returned in Turtle"
	t.end()
