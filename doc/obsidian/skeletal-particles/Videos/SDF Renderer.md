The idea for the tech demo is something that's purposefully upscaled with linear sampling. I want to render lots of shapes at a very low resolution, but still have them appear smooth. 
- The joints of my characters
- Editor widgets, like the grid.
- Background effects
- Particles

SDFs allow you to render smooth shapes at any resolution, at any size.
- Show a circle drawn using geometry
- Their smoothness can be parameterized. Show the edge thickness being interpolated.
- Everything besides SDFs or pixel-perfect sprites becomes a blocky mess.

The core problem is that every shape needs to evaluate a different function, and there's no way to both submit one draw call AND avoid branching on vertex data.

Solution: Just branch, since for a given instance the same branch will be taken every time. 

SDF data is homogeneous; how do we pass it to the GPU?
- Using a union type of every SDF shape makes our instances way larger than they need to be
- Solution: vertex pulling. Each "instance" is now just an index into a big array of floats. When you want to draw an instance on the CPU, you add an instance which marks the shape and the index into the buffer. Then, you push all the parameters piecewise.
- Downside: Requires boilerplate (pushing each member into the buffer, then reading it back out). It's possible to just `memcpy()` on the CPU, but that opens the door to alignment issues.
- Downside upside: The boilerplate is pretty minimal, and forces me to strongly type each SDF shape, which is good.