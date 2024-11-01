SDF shapes morphing into each other, but once upscaled there's a certain pixely, grainy quality. Look at the backgrounds in Animal Well. They're raymarched, which I don't fully understand as opposed to just rendering SDF shapes that blend into each other.

Add basic lighting to the scene. You could give each particle system a normal map; consider a plain circle or cylinder with a normal map in 2D. If you can figure out coherent UV coordinates for each point on the cylinder, you could have a cool 3D look.

Figure out how to build a mesh for each particle system so you can render it as a fluid instead of just the particles. It might be easier to render a translated quad whose UVs map to the fluid sim, and just discard the corners that the capsule cuts off.