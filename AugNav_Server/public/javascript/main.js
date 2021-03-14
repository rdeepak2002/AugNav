// Your web app's Firebase configuration
var firebaseConfig = {
  apiKey: "AIzaSyAJ8B1AhLOBYPcQ15b1UrjfHO1-gY3NPVs",
  authDomain: "fuga-10be6.firebaseapp.com",
  databaseURL: "https://fuga-10be6.firebaseio.com",
  projectId: "fuga-10be6",
  storageBucket: "fuga-10be6.appspot.com",
  messagingSenderId: "1003820827987",
  appId: "1:1003820827987:web:95227d9b3b0120660dcda6",
  measurementId: "G-MEXL5X9G1Y"
}

// Initialize Firebase
firebase.initializeApp(firebaseConfig)
firebase.analytics()

// Firestore database reference
let db = firebase.firestore()

// Email variable to keep track of user logged in
let email = "none"

// Create variable to store map data
let mapData = {}
let mapChosen = {}

// Variable to keep track of optimal path
let optimalPath = []
let optimalPathFound = true

// Detect if user is signed in already
firebase.auth().onAuthStateChanged(function(user) {
  $(".inner-content").fadeOut("slow", function() {
    if (user) {
      email = user.email

      loadHomeScreen()

      $(".inner-content").fadeIn("slow")
    }
    else {
      email = "none"

      loadLoginScreen()

      $(".inner-content").fadeIn("slow")
    }
  })
})

// Clear the container
function clearContainer() {
  $(".inner-content").html("")
}

// Load the login screen
function loadLoginScreen() {
  clearContainer()
  $.get("/public/html/login.html", function (data) {
    $(data).appendTo(".inner-content").hide().fadeIn("slow")
  })
}

// Handle clicking the login button
function login() {
  let email = $(".emailInput").val()
  let password = $(".passwordInput").val()

  firebase.auth().signInWithEmailAndPassword(email, password)
  .catch(function(error) {
    var errorCode = error.code
    var errorMessage = error.message
    alert(errorMessage)
  })
}

// Load the sign up screen
function loadSignUpScreen() {
  clearContainer()
  $.get("/public/html/signup.html", function (data) {
    $(data).appendTo(".inner-content").hide().fadeIn("slow")
  })
}

// Create account
function signUp() {
  let email = $(".emailInputSU").val()
  let password = $(".passwordInputSU").val()
  let cPassword = $(".confirmPasswordInputSU").val()

  if(cPassword == password) {
    firebase.auth().createUserWithEmailAndPassword(email, password).catch(function(error) {
      var errorCode = error.code
      var errorMessage = error.message
      alert(errorMessage)
    })
  }
  else {
    alert("Passwords do not match")
  }
}

// Load the home screen
function loadHomeScreen() {
  clearContainer()
  $.get("/public/html/home.html", function (data) {
    $(data).appendTo(".inner-content").ready(function() {
      $(".home-container").hide()
      $("#canvas-parent").hide()
      $(".welcome-text").html("Welcome, " + email)

      loadMaps()
    })
  })
}

// Load the maps
function loadMaps() {
  db.collection("users").doc(email).collection("maps")
    .get()
    .then(function(querySnapshot) {
        querySnapshot.forEach(function(doc) {
          // Create the card of informtaion of the map
          let cardData = '<div onclick=\'loadMap(\"' + doc.id + '\")\' class="'+
          'card"><div class="container"><h4 class="map-card-header"><b>' +
          doc.id + '</b></h4><p class="map-card-body"> Size of ' +
          doc.data().size + ' vertices</p></div></div>'

          $(".map-container").append(cardData)

          mapData[doc.id]=(doc.data())
        })

        // change next pointers so they are bi-way
        //makeBiWay(mapData)

        $(".home-container").fadeIn("slow")
    })
    .catch(function(error) {
        console.log("Error getting documents: ", error)
    })
}

// Function to make nodes biway
// function makeBiWay(mapDataIn) {
//   for (var map in mapDataIn) {
//     // skip loop if the property is from prototype
//     if (!mapDataIn.hasOwnProperty(map))
//       continue
//
//     let curMap = mapDataIn[map]
//
//     for (var vertex in curMap.data) {
//       // skip loop if the property is from prototype
//       if (!curMap.data.hasOwnProperty(vertex))
//         continue
//
//       let obj = curMap.data[vertex]
//
//       let nextArr = obj["next"]
//
//       for(let i = 0; i < nextArr.length; i++) {
//         curMap.data[nextArr[i]]["next"].push(vertex)
//         curMap.data[nextArr[i]]["next"] = removeDuplicates(curMap.data[nextArr[i]]["next"])
//         nextArr = removeDuplicates(nextArr)
//       }
//     }
//   }
// }

// Remove duplicates after making bi-way
function removeDuplicates(array) {
  return array.filter((a, b) => array.indexOf(a) === b)
}

// Method to handle the loading of maps
function loadMap(mapName) {
  resetScene()

  mapChosen = mapData[mapName]

  let startPoint = "vertex1"
  let endPoint = mapChosen["endVertex"]

  requestForPath(mapChosen, startPoint, endPoint)

  scrollToTop()

  $("#canvas-parent").show()
}

// Send http request to server to find path
function requestForPath(mapDataIn, startPointIn, endPointIn) {
  optimalPathFound = false
  var data = {}

	data.mapDataIn = mapDataIn
  data.startPointIn = startPointIn
  data.endPointIn = endPointIn

	var xmlhttp = new XMLHttpRequest()   // new HttpRequest instance
  let theUrl = "/getPath"

	xmlhttp.open("POST", theUrl)
	xmlhttp.setRequestHeader("Content-Type", "application/json;charset=UTF-8")
	xmlhttp.send(JSON.stringify(data))

	xmlhttp.onload  = function (e) {
	  if (xmlhttp.readyState === 4) {
	    if (xmlhttp.status === 200) {
        let obj = JSON.parse(xmlhttp.responseText);
        optimalPath = obj.exitPath
        optimalPathFound = true
	    } else {
	      console.error(xmlhttp.statusText)
	      console.log(2);
	      alert("Error contacting server.")
        optimalPathFound = true
	    }
	  }
	};
}

// Handle clicking the signout button
function signOut() {
  firebase.auth().signOut().catch(function(error) {
    alert(error)
  })
}
