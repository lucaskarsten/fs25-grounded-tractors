# Acceptance criteria (2026-10-15)

Reference: Case IH Vestrum 130 (base game), ditch next to the road on Krajow, filmed from above and the side.

| Speed | Must look like |
|---|---|
| 5–10 km/h climbing out of the ditch | stays **glued** to the ditch: all four wheels on the ground, no nose-up hang |
| ~40 km/h crossing the ditch | at most the **front wheels lift a little** and come straight back down; the rear never leaves the ground, no roll in the air, no rocking after landing |
| normal driving and turning | steering and cornering feel unchanged |

## What the spike has shown so far

| Knob | Effect |
|---|---|
| wheel damper x6 | no visible change at 40 km/h |
| mass x1.5 | no visible change at either speed |
| body angular damping 5 | glued at 40 km/h, but looks stiff |
| body angular damping 1–2 | no flight at 43 km/h; at 1, slow ditch exit hangs in slow motion |
| CoM 0.5 m forward + 0.3 m lower | slow exit improved (filmed with the front-axle bug, re-test pending) |
| ballast + angular damping 1 (fixed axle) | **rejected**: slow exit "takes off like a plane", damping holds the pitch angle after the ramp ends. Constant angular damping is the wrong tool |
| ballast + travel x2 (19-51-18) | **worse**: clear 4-wheel jump at 43 km/h, >0.5 s airborne. Long travel stores energy and returns it |
| ballast + travel x0.2 (same video) | small, short hop at ~40 km/h, lands quickly; closest to the criterion so far |
| ballast + travel x0.4 + gtAir 2 (19-55-53) | **candidate**: at 42 km/h the nose lifts ~0.5 s, low hop, lands without roll or rocking; slow exit (5-10 km/h) stays on all four wheels |

Shipped as the 1.0 defaults (`gtComZ 0.5`, `gtCom 0.3`, `gtTravel 0.4`, `gtAir 2`). Rows above were tested with the spike's `hf*` command names.

Stock values: chassis 3.53 t, front axle 1.00 t, angular damping 0.010 on both, suspension travel 9/12 cm.
