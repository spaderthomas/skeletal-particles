SDF shapes morphing into each other, but once upscaled there's a certain pixely, grainy quality. Look at the backgrounds in Animal Well. They're raymarched, which I don't fully understand as opposed to just rendering SDF shapes that blend into each other.

Add basic lighting to the scene. You could give each particle system a normal map; consider a plain circle or cylinder with a normal map in 2D. If you can figure out coherent UV coordinates for each point on the cylinder, you could have a cool 3D look.

Figure out how to build a mesh for each particle system so you can render it as a fluid instead of just the particles. It might be easier to render a translated quad whose UVs map to the fluid sim, and just discard the corners that the capsule cuts off.

Use an edge shader (probably on the upscaled texture) to outline the blocky things

---

Things I still need to do, in no particular order
- Push back to the main engine branch and make sure it works. 
- Change the repo structure so that you pull the engine as a submodule and rebase onto it.
	- The build script should be in the scaffolding repo
- Add a `config.hpp` file, which lets you tweak the sizes of internal buffers and such
- Hijack main
- Your app should be a struct, instead of the one callback thing you have

SDF
- Interpolate between colors
- Generate a more-correct bounding box for combinations
- Add more shapes and clean up the API
- Allow the caller to configure `k`

RENDERER
- Build an SDF renderer into the engine and replace all the `draw_*` APIs with that
- Remove the second attempt at a graphics API
- Render the editor (i.e. a grid and colliders)

LIGHTS
- Reimplement the lighting pass in the new graphics API and light a basic shape
- Generate correctly rotated UVs for each shape