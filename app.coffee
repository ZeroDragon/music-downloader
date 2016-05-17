request = require 'request'
progress = require 'request-progress'
fs = require 'fs'
async = require 'async'
sanitize = require "sanitize-filename"

done = 0
todo = 0
error = 0
items = {}
simul = 50
console.time 'Total Time'
report = (item,percent)->
	items[item] = percent
	process.stdout.write "\u001b[2J\u001b[0;0H"
	for i,k in Object.keys(items)
		v = items[i]
		console.log "[#{v}%]: #{i}"
	for i in [0...(Object.keys(items).length-simul)]
		console.log "[*]"
	console.log "\nDone: #{done} | To Do: #{todo} | Errors: #{error}"

q = async.queue (task,callback)->
	file = fs.createWriteStream("#{__dirname}/downloads/#{sanitize(task.title)}.mp3")
	progress(
		request(task.url),{}
	)
		.on 'progress', (state)->
			report task.title,(state.percentage*100).toFixed(2)
		.on('end',->
			delete items[task.title]
			done++
			callback()
		)
		.on 'error', ->
			error++
			callback()
		.pipe(file)
	file.on 'error', ->
		error++
		callback()
,simul

q.drain = ->
	if q.running() + q.length() is 0
		process.stdout.write "\u001b[2J\u001b[0;0H"
		console.log "\nDone: #{done} | To Do: #{todo} | Errors: #{error}"
		console.timeEnd 'Total Time'
		console.log "Finished, enjoy"

request.get "http://www.getworkdonemusic.com/fast_tracks.json", {json:true}, (err,data,body)->
	todo += body.length
	q.push body.map((e)-> {url:e.stream_url+'?consumer_key=ffd65a79a82483821934415715bff247',title:e.title})

	request.get "http://www.getworkdonemusic.com/faster_tracks.json", {json:true}, (err,data,body)->
		todo += body.length
		q.push body.map((e)-> {url:e.stream_url+'?consumer_key=ffd65a79a82483821934415715bff247',title:e.title})
