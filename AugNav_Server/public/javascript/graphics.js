let scene, renderer, camera;
let cube;
let controls;

let width = window.innerWidth
let height = window.innerHeight

let shapesDrawn = false
let scale = 100

let moveForward = false
let moveBackward = false
let moveLeft = false
let moveRight = false
let moveUp = false
let moveDown = false

let velocity = new THREE.Vector3();
let direction = new THREE.Vector3();

let vertexTitles = []

let northMesh
let eastMesh
let southMesh
let westMesh

let drawSize = 0

init();
animate();

function init()
{
    renderer = new THREE.WebGLRenderer( {antialias:true} );
    let container = document.getElementById('canvas-parent');

    renderer.setSize (width, height);
    renderer.setClearColor (0xEAEEF1, 1);
    container.appendChild (renderer.domElement);

    scene = new THREE.Scene();

    camera = new THREE.PerspectiveCamera (45, width/height, 1, 10000);
    camera.position.y = 160;
    camera.position.z = 400;
    camera.lookAt (new THREE.Vector3(0,0,0));

    controls = new THREE.PointerLockControls( camera, renderer.domElement );

    // User interaction needed for initial pointer lock control sequence
    container.addEventListener( 'click', function () {
    	 controls.lock();
    }, false );

    scene.add( controls.getObject() );

    var onKeyDown = function ( event ) {
      switch ( event.keyCode ) {
        case 38: // up
        case 87: // w
        	moveForward = true;
        	break;

        case 37: // left
        case 65: // a
        	moveLeft = true;
        	break;

        case 40: // down
        case 83: // s
        	moveBackward = true;
        	break;

        case 39: // right
        case 68: // d
        	moveRight = true;
        	break;

        case 82: // r
          moveUp = true;
          break;

        case 70: // f
          moveDown = true;
          break;
      };
    };

		var onKeyUp = function ( event ) {
      switch ( event.keyCode ) {
				case 38: // up
				case 87: // w
					moveForward = false;
					break;

				case 37: // left
				case 65: // a
					moveLeft = false;
					break;

				case 40: // down
				case 83: // s
					moveBackward = false;
					break;

				case 39: // right
				case 68: // d
					moveRight = false;
					break;

        case 82: // r
          moveUp = false;
          break;

        case 70: // f
          moveDown = false;
          break;
			}
		};

	document.addEventListener( 'keydown', onKeyDown, false );
	document.addEventListener( 'keyup', onKeyUp, false );
}

function resetScene() {
  scene.remove.apply(scene, scene.children)
  drawSize = 0
  shapesDrawn = false
  optimalPath = []
  camera.position.y = 160
  camera.position.z = 400
  camera.lookAt (new THREE.Vector3(0,0,0))
  optimalPathFound = false
}

function animate()
{
  requestAnimationFrame ( animate );
  renderer.render (scene, camera);

  if(northMesh != undefined && southMesh != undefined) {
    northMesh.position.y = camera.position.y
    northMesh.position.z = camera.position.z - 500
    northMesh.position.x = camera.position.x
    northMesh.lookAt( camera.position )

    southMesh.position.y = camera.position.y
    southMesh.position.z = camera.position.z + 500
    southMesh.position.x = camera.position.x
    southMesh.lookAt( camera.position )

    eastMesh.position.y = camera.position.y
    eastMesh.position.z = camera.position.z
    eastMesh.position.x = camera.position.x + 500
    eastMesh.lookAt( camera.position )

    westMesh.position.y = camera.position.y
    westMesh.position.z = camera.position.z
    westMesh.position.x = camera.position.x - 500
    westMesh.lookAt( camera.position )
  }

  if(drawSize < 100) {
    for(let i = 0; i < vertexTitles.length; i++) {
      vertexTitles[i].lookAt( camera.position );
    }
  }
  else {
    console.log("Too many verticies to have look at feature")
  }

  if(optimalPathFound)
    if(!shapesDrawn)
      drawMap()

  if ( controls.isLocked === true ) {
    if(moveForward == true)
      direction.z = -1.0
    else if(moveBackward == true){
      direction.z = 1.0
    }
    else if(moveForward == false && moveBackward == false){
      direction.z = 0
    }

    if(moveRight == true)
      direction.x = -1.0
    else if(moveLeft == true){
      direction.x = 1.0
    }
    else if(moveRight == false && moveLeft == false){
      direction.x = 0
    }

    if(moveUp == true)
      direction.y = 1.0
    else if(moveDown == true){
      direction.y = -1.0
    }
    else if(moveUp == false && moveDown == false){
      direction.y = 0
    }

    direction.normalize(); // this ensures consistent movements in all directions

    velocity.z = direction.z * 2;
    velocity.x = direction.x * 2;
    velocity.y = direction.y * 2;

    controls.moveRight( - velocity.x);
		controls.moveForward( - velocity.z);
    controls.getObject().position.y += (velocity.y);
	}
}

function drawMap() {
  console.log("drawing 3d map")

  if(mapChosen.data != undefined) {
    let loader = new THREE.FontLoader();

    // Load North label
    loader.load( 'fonts/helvetiker_regular.typeface.json', function ( font ) {
      let textGeometry = new THREE.TextGeometry( "NORTH", {
        font: font,
        size: 80,
        height: 5,
        curveSegments: 12,
        bevelEnabled: true,
        bevelThickness: 10,
        bevelSize: 4,
        bevelOffset: 0,
        bevelSegments: 5
      } );

      let textMaterial = new THREE.MeshBasicMaterial ({color: 0x0000ff});
      northMesh = new THREE.Mesh (textGeometry, textMaterial);
      northMesh.scale.x = northMesh.scale.y = northMesh.scale.z = 0.1
      northMesh.position.set (0, 0, -100);
      northMesh.position.y = camera.position.y
      northMesh.position.z = camera.position.z - 500
      northMesh.position.x = camera.position.x
      scene.add(northMesh)
    });

    // Load South label
    loader.load( 'fonts/helvetiker_regular.typeface.json', function ( font ) {
      let textGeometry = new THREE.TextGeometry( "SOUTH", {
        font: font,
        size: 80,
        height: 5,
        curveSegments: 12,
        bevelEnabled: true,
        bevelThickness: 10,
        bevelSize: 4,
        bevelOffset: 0,
        bevelSegments: 5
      } );

      let textMaterial = new THREE.MeshBasicMaterial ({color: 0x0000ff});
      southMesh = new THREE.Mesh (textGeometry, textMaterial);
      southMesh.scale.x = southMesh.scale.y = southMesh.scale.z = 0.1
      southMesh.position.set (0, 0, -100);
      southMesh.position.y = camera.position.y
      southMesh.position.z = camera.position.z + 500
      southMesh.position.x = camera.position.x
      scene.add(southMesh)
    });

    // Load East label
    loader.load( 'fonts/helvetiker_regular.typeface.json', function ( font ) {
      let textGeometry = new THREE.TextGeometry( "EAST", {
        font: font,
        size: 80,
        height: 5,
        curveSegments: 12,
        bevelEnabled: true,
        bevelThickness: 10,
        bevelSize: 4,
        bevelOffset: 0,
        bevelSegments: 5
      } );

      let textMaterial = new THREE.MeshBasicMaterial ({color: 0x0000ff});
      eastMesh = new THREE.Mesh (textGeometry, textMaterial);
      eastMesh.scale.x = eastMesh.scale.y = eastMesh.scale.z = 0.1
      eastMesh.position.set (0, 0, -100);
      eastMesh.position.y = camera.position.y
      eastMesh.position.z = camera.position.z
      eastMesh.position.x = camera.position.x + 500
      scene.add(eastMesh)
    });

    // Load West label
    loader.load( 'fonts/helvetiker_regular.typeface.json', function ( font ) {
      let textGeometry = new THREE.TextGeometry( "WEST", {
        font: font,
        size: 80,
        height: 5,
        curveSegments: 12,
        bevelEnabled: true,
        bevelThickness: 10,
        bevelSize: 4,
        bevelOffset: 0,
        bevelSegments: 5
      } );

      let textMaterial = new THREE.MeshBasicMaterial ({color: 0x0000ff});
      westMesh = new THREE.Mesh (textGeometry, textMaterial);
      westMesh.scale.x = westMesh.scale.y = westMesh.scale.z = 0.1
      westMesh.position.set (0, 0, -100);
      westMesh.position.y = camera.position.y
      westMesh.position.z = camera.position.z
      westMesh.position.x = camera.position.x - 500
      scene.add(westMesh)
    });

    let gridXZ = new THREE.GridHelper(2000, 50);
    scene.add(gridXZ);

    for (var vertex in mapChosen.data) {
      // skip loop if the property is from prototype
      if (!mapChosen.data.hasOwnProperty(vertex))
        continue

      let obj = mapChosen.data[vertex]

      let name = obj["name"]
      let x = obj["x"]*scale
      let y = obj["y"]*scale
      let z = obj["z"]*scale
      let radius = obj["radius"]*2*scale
      let nextArr = obj["next"]

      // fill(color("black"))

      for(let i = 0; i < nextArr.length; i++) {
        let nextX = mapChosen.data[nextArr[i]]["x"]*scale
        let nextZ = mapChosen.data[nextArr[i]]["z"]*scale
        let nextY = mapChosen.data[nextArr[i]]["y"]*scale

        //create a blue LineBasicMaterial
        let material = new THREE.LineBasicMaterial( { color: 0x0000ff } );

        // Make correct path green
        if(optimalPath != undefined && optimalPath.indexOf(vertex) != -1 && optimalPath.indexOf(nextArr[i]) != -1) {
          material = new THREE.LineBasicMaterial( { color: 0x00ff00 } );
        }

        let points = [];
        points.push( new THREE.Vector3( x, y, z ) );
        points.push( new THREE.Vector3( nextX, nextY, nextZ, ) );

        let geometry = new THREE.BufferGeometry().setFromPoints( points );

        let line = new THREE.Line( geometry, material );

        scene.add( line );
      }
      let cubeMaterial = new THREE.MeshBasicMaterial ({color: 0xff0000});

      let cubeGeometry = new THREE.BoxGeometry (radius,radius,radius);
      cube = new THREE.Mesh (cubeGeometry, cubeMaterial);
      cube.position.set (x, y, z);
      scene.add (cube);

      let loader = new THREE.FontLoader();

      loader.load( 'fonts/helvetiker_regular.typeface.json', function ( font ) {
      	let textGeometry = new THREE.TextGeometry( name, {
      		font: font,
      		size: 80,
      		height: 5,
      		curveSegments: 12,
      		bevelEnabled: true,
      		bevelThickness: 10,
      		bevelSize: 4,
      		bevelOffset: 0,
      		bevelSegments: 5
      	} );

        let textMaterial = new THREE.MeshBasicMaterial ({color: 0x000000});
        let textMesh = new THREE.Mesh (textGeometry, textMaterial);
        textMesh.scale.x = textMesh.scale.y = textMesh.scale.z = 0.1
        textMesh.position.set (x, y + radius*1.2, z);
        textMesh.lookAt( camera.position );
        scene.add (textMesh);

        vertexTitles.push(textMesh)
      });

      drawSize++
    }
  }

  console.log("Drew " + drawSize + " vertices")

  shapesDrawn = true
}

window.addEventListener( 'resize', onWindowResize, false );

function onWindowResize(){
  if(camera != undefined) {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();

    renderer.setSize( window.innerWidth, window.innerHeight );
  }

  width = window.innerWidth
  height = window.innerHeight
}

// Scrolling to top
function scrollToTop() {
  window.scrollTo(0, 0)
}
