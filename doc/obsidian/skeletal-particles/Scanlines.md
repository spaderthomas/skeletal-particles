- [ ] A wave is mapped onto the screen. At the bottom of the wave, the row of pixels remains unchanged. As you go to the top of the wave, the color becomes more saturated and darker (i.e. lower value)

| S0  | S1  | V0  | V1  | Color      |
| --- | --- | --- | --- | ---------- |
| 54  | 99  | 99  | 92  | Light Blue |
| 39  | 81  | 78  | 64  | Purple     |
| 2   | 30  | 67  | 42  | Dark Text  |
| 37  | 66  | 100 | 92  | Pink       |
|     |     |     |     |            |

Try to upscale the texture to the output resolution, and then apply these effects. You end up with artifacts at the lowest resolution (and scanlines are in fact turned off in the game when the resolution is low).


---

There is a dark blue that bleeds from bright areas in a scanline pattern; the color is uniform regardless of what it is blooming.

What if we make a bloom map, and then combine that with the scanlines? So, use the brightness of the bloom pixel as a lerp between the color and the scanline color.

---

First, do chromatic aberration. Then, bloom. That's gonna make sure that 

Everything gets darker and more blue, according to some ratio, along the scanlines. That means that its hue approaches 240, its value decreases, and it generally becomes more saturated. The bloom is also scanlined; the bloom looks like it's blue, and then gets faded out where there is a scanline. The scanline is not blending a color with the line. It's moving the color in HSV space.

I think that the scanline effect is applied last.

1. Calculate the bloom map, which is just going to be "write a 1 everywhere there is a non-black pixel" (maybe threshold it, who cares) and then blur it a few times
2. Apply chromatic aberration by using the value from the bloom map to determine your saturation and stuff. 1 = dont do anything, 0 = fully interpolated to black. you can use two channels in bloom map, one for left edge and one for right edge, not totally sure how to do this (again maybe subtract out source pixel?)
3. Blur it with a tight blur. This is what gives you the nice gradient on the aberration. 
	1. Keep the colors saturated. GPT tells me to indeed convert to HSV and use a log curve to mix colors non-linearly
4. Apply a blue bloom according to the bloom map; subtract off the intensity of the pixel so that it only applies at dark to light boundaries
5. Apply the scanline; at each row, calculate the scanline intensity, and then move the color by saturating it and making its value lower (i.e. darker)
	1. Use the current saturation as an input to the mapping function. Try a quadratic ease out, so that very unsaturated colors gain more saturation.
	2. For value, try a quadratic ease in.
	3. Threshold saturation and if below .1, set hue to light blue (210)

-  [ ] Chromatic aberration is blurred smoothly and with more saturation
-  [ ] Bloom appears opposite scanlines
-  [ ] Whites and grays become blue over scanlines


