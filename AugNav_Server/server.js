const express = require('express')
const nocache = require('nocache')
const http = require('http')
const cors = require('cors')
var bodyParser = require('body-parser');

let app = express()
let server = http.Server(app)
let port = process.env.PORT || 8080

app.use(express.static(__dirname))
app.use(nocache())
app.use(cors())
app.use(bodyParser.json())
app.use(bodyParser.urlencoded({ extended: true }))

// Return app.html page by default
app.get('/', function(req, res) {
	res.sendFile(__dirname + '/public/html/app.html')
});

// Post request to get the exit path
app.post('/getPath', function(req, res){
	let mapData = req.body.mapDataIn
  let startPoint = req.body.startPointIn
  let endPoint = req.body.endPointIn

	console.log(req.body)

	let possiblePaths = []

	let response = { exitPath: []}

	if(mapData["data"].hasOwnProperty(startPoint) && mapData["data"].hasOwnProperty(endPoint) && mapData["size"] > 0) {
		findExitPath(mapData, startPoint, endPoint, startPoint, [], possiblePaths)

		let optimalPath = findOptimalPath(possiblePaths, mapData)

	  response = {
		  exitPath : optimalPath
		}
	}

	res.send(response)
})

// Function to find all possible exit paths
function findExitPath(mapDataIn, startVertex, endVertex, curVertex, path, possiblePathsIn) {
  const tempPath = [...path]

  let curMap = mapDataIn

  if(curVertex === endVertex) {
    tempPath.push(curVertex)
    possiblePathsIn.push(tempPath)
  }
  else if(tempPath.length <= mapDataIn["size"] && !tempPath.includes(curVertex)) {
    tempPath.push(curVertex)

    let nextArr = curMap.data[curVertex]["next"]

    for(let i = 0; i < nextArr.length; i++) {
      let nextVertex = nextArr[i]
      let tempExitPath = findExitPath(mapDataIn, startVertex,
        endVertex, nextVertex, tempPath, possiblePathsIn)
    }
  }
}

// Function to return the best exit path from all possible paths
function findOptimalPath(possiblePathsIn, mapDataIn) {
  let minDistance = mapDataIn["size"] + 1
  let bestPathIndex = -1

  for(let i = 0; i < possiblePathsIn.length; i++) {
    if(possiblePathsIn[i].length <= minDistance) {
      minDistance = possiblePathsIn[i].length
      bestPathIndex = i
    }
  }

  return possiblePathsIn[bestPathIndex]
}

// Return app.html page by default
app.get('*', function(req, res) {
	res.sendFile(__dirname + '/public/html/app.html')
})

// Listen on port
server.listen(port, function() {
  console.log('listening on:' + port)
})
