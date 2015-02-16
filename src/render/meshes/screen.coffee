Base            = require './base'
ScreenGeometry  = require('../geometry').ScreenGeometry
Util            = require '../../util'

class Screen extends Base
  constructor: (renderer, shaders, options) ->
    super renderer, shaders, options

    uniforms = options.uniforms ? {}
    fragment = options.fragment

    hasStyle = uniforms.styleColor?

    @geometry = new ScreenGeometry
      width:    options.width
      height:   options.height

    @_adopt uniforms
    @_adopt @geometry.uniforms

    factory = shaders.material()

    v = factory.vertex
    v.pipe    'raw.position.scale', @uniforms
    v.fan()
    v  .pipe  'stpq.xyzw.2d',       @uniforms
    v.next()
    v  .pipe  'screen.position',    @uniforms
    v.join()

    f = factory.fragment
    f.require options.fragment
    f.pipe    'stpq.sample.2d'
    if hasStyle
      f.pipe  'style.color',        @uniforms
      f.pipe  Util.GLSL.binaryOperator 'vec4', '*'
    f.pipe    'fragment.color'

    @material = @_material factory.link
      side: THREE.DoubleSide
      defaultAttributeValues: null
      index0AttributeName: "position4"

    object = new THREE.Mesh @geometry, @material
    object.frustumCulled = false

    @_raw object
    @objects = [object]

  dispose: () ->
    @geometry.dispose()
    @material.dispose()
    @objects = @geometry = @material = null
    super

module.exports = Screen