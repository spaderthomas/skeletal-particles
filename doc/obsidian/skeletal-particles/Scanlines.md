- [ ] A wave is mapped onto the screen. At the bottom of the wave, the row of pixels remains unchanged. As you go to the top of the wave, the color becomes more saturated and darker (i.e. lower value)

| S0  | S1  | V0  | V1  | Color      |
| --- | --- | --- | --- | ---------- |
| 54  | 99  | 99  | 92  | Light Blue |
| 39  | 81  | 78  | 64  | Purple     |
| 2   | 30  | 67  | 42  | Dark Text  |
| 37  | 66  | 100 | 92  | Pink       |
|     |     |     |     |            |

Try to upscale the texture to the output resolution, and then apply these effects. You end up with artifacts at the lowest resolution (and scanlines are in fact turned off in the game when the resolution is low).