# WebGL example powered by three.js
# This example is originated from http://mrdoob.github.com/three.js/examples/webgl_geometries.html

$window = MrubyJs::get_root_object
$document = $window.document
$three = $window.THREE

$container = $stats = nil
$camera = $scene = $renderer = nil

unless $window.Detector.webgl
  $window.Detector.addGetWebGLMessage[]
end

def onWindowResize
  if $camera
    $camera.aspect = $window.innerWidth / $window.innerHeight
    $camera.updateProjectionMatrix[]
  end

  if $renderer
    $renderer.setSize($window.innerWidth, $window.innerHeight)
  end
end

def init
  $container = $document.createElement('div')
  $document.body.appendChild($container)

  $camera = $three.PerspectiveCamera.invoke_new(
      45, $window.innerWidth / $window.innerHeight, 1, 2000)
  $camera.position.y = 400

  $scene = $three.Scene.invoke_new

  $scene.add($three.AmbientLight.invoke_new(0x404040))

  light = $three.DirectionalLight.invoke_new(0xffffff)
  light.position.call(:set, 0, 1, 0)
  $scene.add(light)

  map = $three.ImageUtils.loadTexture("textures/ash_uvgrid01.jpg")
  map.wrapS = map.wrapT = $three.RepeatWrapping
  map.anisotropy = 16

  materials = [$three.MeshLambertMaterial.invoke_new({ambient: 0xbbbbbb, map: map, side: $three.DoubleSide}),
               $three.MeshBasicMaterial.invoke_new({color: 0xffffff, wireframe: true, transparent: true, opacity: 0.1, side: $three.DoubleSide})]

  object_create_func = $three.SceneUtils.createMultiMaterialObject

  object = object_create_func[$three.CubeGeometry.invoke_new(100, 100, 100, 4, 4, 4), materials]
  object.position.call(:set, -200, 0, 400)
  $scene.add(object)

  object = object_create_func[$three.CylinderGeometry.invoke_new(25, 75, 100, 40, 5), materials]
  object.position.call(:set, 0, 0, 400)
  $scene.add(object)

  object = object_create_func[$three.IcosahedronGeometry.invoke_new(75, 1), materials]
  object.position.call(:set, -200, 0, 200)
  $scene.add(object)

  object = object_create_func[$three.OctahedronGeometry.invoke_new(75, 2), materials]
  object.position.call(:set, 0, 0, 200)
  $scene.add(object)

  object = object_create_func[$three.TetrahedronGeometry.invoke_new(75, 0), materials]
  object.position.call(:set, 200, 0, 200)
  $scene.add(object)

  object = object_create_func[$three.PlaneGeometry.invoke_new(100, 100, 4, 4), materials]
  object.position.call(:set, -200, 0, 0)
  $scene.add(object)

  object2 = object_create_func[$three.CircleGeometry.invoke_new(50, 10, 0, Math::PI), materials]
  object2.rotation["x"] = Math::PI / 2
  object.add(object2)

  object = object_create_func[$three.SphereGeometry.invoke_new(75, 20, 10), materials]
  object.position.call(:set, 0, 0, 0)
  $scene.add(object)

  points = []
  vector3_func = $three.Vector3
  50.times do |i|
    points << vector3_func.invoke_new(Math.sin(i * 0.2) * 15 + 50, 0, (i - 5) * 2)
  end

  object = object_create_func[$three.LatheGeometry.invoke_new(points, 20), materials]
  object.position.call(:set, 200, 0, 0)
  $scene.add(object)

  object = object_create_func[$three.TorusGeometry.invoke_new(50, 20, 20, 20), materials]
  object.position.call(:set, -200, 0, -200)
  $scene.add(object)

  object = object_create_func[$three.TorusKnotGeometry.invoke_new(50, 10, 50, 20), materials]
  object.position.call(:set, 0, 0, -200)
  $scene.add(object)

  object = $three.AxisHelper.invoke_new(50)
  object.position.call(:set, 200, 0, -200)
  $scene.add(object)

  object = $three.ArrowHelper.invoke_new(vector3_func.invoke_new(0, 1, 0),
                                         vector3_func.invoke_new(0, 0, 0), 50)
  object.position.call(:set, 200, 0, 400)
  $scene.add(object)

  $renderer = $three.WebGLRenderer.invoke_new({antialias: true})
  $renderer.setSize($window.innerWidth, $window.innerHeight)

  $container.appendChild($renderer.domElement)

  $stats = $window.Stats.invoke_new
  $stats.domElement.style.position = 'absolute'
  $stats.domElement.style.top = '0px'
  $container.appendChild( $stats.domElement )

  $window.addEventListener('resize', :onWindowResize.to_proc, false)
end

def do_render
  t = Time.now
  timer = t.sec * 0.1 + t.usec * 0.0000001

  $camera.position.x = Math.cos(timer) * 800
  $camera.position.z = Math.sin(timer) * 800

  $camera.lookAt( $scene.position )

  $scene.children.each do |object|
    object.rotation.x = timer * 5
    object.rotation.y = timer * 2.5
  end

  $renderer.render($scene, $camera)
end

def animate
  $window.requestAnimationFrame(:animate.to_proc)

  do_render
  $stats.update[]
end

init
animate
