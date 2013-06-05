MrubyJs.window.instance_eval do
  Detector = get(:Detector)
  THREE = get(:THREE)
  Stats = get(:Stats)

  unless Detector.webgl
    Detector.addGetWebGLMessage[]
  end

  [:stats, :camera, :scene, :renderer, :clock,
   :uniforms1, :uniforms2].each do |v|
    set(v, nil)
  end
  window.meshes = []
  window.clock = THREE.Clock.invoke_new

  def init
    container = document.getElementById "container"
    windowHalfX = innerWidth / 2;
    windowHalfY = innerHeight / 2;

    window.camera = THREE.PerspectiveCamera.invoke_new(40, windowHalfX / windowHalfY,
                                                     1, 3000)
    window.camera.position.z = 4

    window.scene = THREE.Scene.invoke_new

    window.uniforms1 = {
      time: { type: "f", value: 1.0 },
      resolution: { type: "v2", value: THREE.Vector2.invoke_new }
    }
    window.uniforms2 = {
      time: { type: "f", value: 1.0 },
      resolution: { type: "v2", value: THREE.Vector2.invoke_new },
      texture: { type: "t", value:
        THREE.ImageUtils.loadTexture("textures/disturb.jpg")}
    }
    window.uniforms2[:texture][:value].wrapS = window.uniforms2[:texture][:value].wrapT = THREE.RepeatWrapping

    size = 0.75
    mlib = []

    params = [ [ 'fragment_shader1', window.uniforms1 ],
               [ 'fragment_shader2', window.uniforms2 ],
               [ 'fragment_shader3', window.uniforms1 ],
               [ 'fragment_shader4', window.uniforms1 ]]

    params.each_index do |i|
      material = THREE.ShaderMaterial.invoke_new(uniforms: params[i][1],
                                                 vertexShader: document.getElementById('vertexShader').textContent,
                                                 fragmentShader: document.getElementById(params[i][0]).textContent)

      mlib[i] = material

      mesh = THREE.Mesh.invoke_new(THREE.CubeGeometry.invoke_new(size, size, size),
                                   THREE.MeshFaceMaterial.invoke_new([mlib[i]] * 6))
      mesh.position.x = i - (params.length - 1) / 2.0
      mesh.position.y = i % 2 - 0.5
      window.scene.add mesh

      window.meshes[i] = mesh
    end

    window.renderer = THREE.WebGLRenderer.invoke_new
    container.appendChild(window.renderer.domElement)

    window.stats = Stats.invoke_new
    window.stats.domElement.style.position = 'absolute'
    window.stats.domElement.style.top = '0px';
    container.appendChild window.stats.domElement

    onWindowResize
    addEventListener('resize', :onWindowResize.to_js_proc(self, 0), false)
  end

  def onWindowResize
    window.uniforms1.resolution.value.x = window.innerWidth
    window.uniforms1.resolution.value.y = window.innerHeight

    window.uniforms2.resolution.value.x = window.innerWidth
    window.uniforms2.resolution.value.y = window.innerHeight

    window.camera.aspect = window.innerWidth / window.innerHeight
    window.camera.updateProjectionMatrix

    window.renderer.setSize(window.innerWidth, window.innerHeight)
  end

  def animate
    requestAnimationFrame(:animate.to_js_proc(self, 0))

    delta = window.clock.getDelta()

    window.uniforms1.time.value += delta * 5
    window.uniforms2.time.value = clock.elapsedTime

    # meshes is a JS array
    0.upto(window.meshes.length - 1) do |i|
      window.meshes[i].rotation.y += delta * 0.5 * ( i % 2 ? 1 : -1)
      window.meshes[i].rotation.x += delta * 0.5 * ( i % 2 ? -1 : 1)
    end

    window.renderer.render(window.scene, window.camera)

    window.stats.update[]
  end

  init
  animate
end
