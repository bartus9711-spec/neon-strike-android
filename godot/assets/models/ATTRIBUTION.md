# TeamCS 3D human character attribution

Both character models are included in generated Android builds under **Creative Commons Attribution 4.0 International (CC BY 4.0)**.

- `soldier.glb`: "[FREE] Military Soldier RIGGED", created by BAMEN; distributed under CC BY 4.0. Source: https://sketchfab.com/3d-models/free-military-soldier-rigged-e9c56308a67d4a3db62e914fafa4d198
- `soldier_tac.glb`: "Military tactical suit (LowPolyGameReady)", created by DanlyVostok (1799danly); distributed under CC BY 4.0. Source: https://sketchfab.com/3d-models/military-tactical-suit-lowpolygameready-ef698ce36b1545a78ce592dd3db4c7ed

These models are redistributed in an adapted, game-integrated context and downloaded from a pinned snapshot of https://github.com/cktang88/3d-fps/tree/130ac2a5c856401ec36e7d35afcfefe40c5801f4/public/assets/models/characters.

Licensing information: https://creativecommons.org/licenses/by/4.0/

## Animation and upstream adaptation credits

The pinned upstream [README](https://github.com/cktang88/3d-fps/blob/130ac2a5c856401ec36e7d35afcfefe40c5801f4/README.md) also credits assets embedded in `soldier.glb`:

- Quaternius, **Universal Animation Library 1 & 2 (Standard)**, CC0, https://quaternius.com — retargeted animation clips.
- Ian Mason, Sebastian Starke and Taku Komura, **100STYLE** dataset, CC BY 4.0, https://zenodo.org/records/8127870 — walk/jog/crouch motion in the `mocap_*` clips, extracted, loop-closed and retargeted upstream.
- Upstream adapted the tactical meshes and converted their textures to WebP. Its GLB metadata independently identifies DanlyVostok, the original Sketchfab URL and CC-BY-4.0.

TeamCS adaptations: skin-aware fitting to 1.75 m, clothing colour/roughness overrides, and repositioned headset bind transforms. Original GLB files remain unchanged. No new third-party model was added in the rendering repair.

`tactical_motion.tres` is a TeamCS adaptation of the existing BAMEN rig and embedded
animation data to DanlyVostok's tactical suit. It combines the `ready_idle` upper-body
pose with 100STYLE `mocap_walk_F_1_1733`, `mocap_jog_F_1_7529`, and
`mocap_run2_F_2_0049` lower-body cycles from the pinned upstream GLB. TeamCS changes:
bind-space retargeting, target limb proportions, grounded vertical displacement,
closed loops and subtle authored idle breathing. Retain the CC BY 4.0 attribution
above when redistributing this adapted animation resource.

This file must remain packaged alongside distributed source/project credits. Other TeamCS procedural art is original.
