# 🚀 Aseprite 2.5D Animation Pipeline

> 🌐 _**English** · [Español](README.md)_

Three **pure-Lua scripts for Aseprite** (no dependencies, nothing to compile) to animate sprites and prepare them for dynamic lighting in engines like Godot, Unity or Defold.

- 🧬 **Skeleton2Animation** — bone-based animation (hierarchical skeleton).
- 🔄 **Tween** — interpolate motion, rotation, scale and color between poses.
- 💡 **NormalMap** — generate normal maps for 2.5D lighting.

> 💡 **Note:** these are not meant to replace paid extensions. They are free and they work; the UI is functional, not pretty.

---

## ✅ Requirements

- **Aseprite** with scripting support (`File > Scripts` menu).
- **Tween** and **NormalMap** work **only in RGB color mode** (`Sprite > Color Mode > RGB`).
- The `.lua` files must be saved as **UTF-8 without BOM** (Aseprite won't run scripts with a BOM).

---

## ⚙️ Installation

1. Download the `.lua` files from the [`scripts/`](scripts/) folder.
2. In Aseprite: **File > Scripts > Open Scripts Folder**.
3. Copy the files into that folder.
4. Back in **File > Scripts**, click **Rescan Scripts** (or press `F5`). Run each one from that same menu.

---

## 🧬 1. Skeleton2Animation.lua — Bone animation

Builds a parent-child bone skeleton on top of your sprite, binds each layer (a limb) to a bone, and animates by moving/rotating bones. It stores a **rest pose** to return to, and exports poses to **JSON**.

<!-- 🎬 Demo GIF -->
> _(GIF pending)_

**How to use it:**

1. Open your sprite with each body part on **its own layer** (e.g. `Head`, `Body`, `LegFR`…) and run the script. Opening it does **not** modify the sprite until you take an action.
2. Create the bones:
   - **Auto-detect bones**: creates one bone per image layer, all hanging from the root.
   - Or manually with the name + **`+`** / **`-`** buttons.
3. Define the hierarchy with **Reparent** (choose which bone hangs from which).
4. Bind the skin to the bone (matching is by **layer name = bone name**):
   - **Bind layer**: attaches the whole active layer to the selected bone.
   - **Bind skin**: crops the active selection and creates the bone's skin.
   - (Auto-detect already leaves everything bound.)
5. Animate:
   - **Move node**: moves the bone and its skin. **Move bone only**: just the pivot.
   - **Rotation** slider (with / without children). While rotating, the skeleton hides so you can see the skin; it reappears on release or when you switch mode.
6. **Create frame**: copies the current pose to a new frame and returns frame 1 to the **rest pose** so you can build the next one.
7. **Restore rest pose**: returns everything to rest (handy when undo gets messy).
8. **Save** / **Load**: exports or imports the pose as JSON. On load, it automatically re-binds each bone to its same-named layer.

**Data:** the pose is saved to a `.json` with the hierarchy, positions and rest pose. The image is not stored there: it is recovered from the layers by name on load.

**Origin:** based on [**aimarzhang**'s Skeleton2Animation](https://aimarzhang.itch.io/skeleton2animation-in-aseprite/devlog/943953/skeleton2animation-in-aseprite), heavily modified and adapted (fixing quite a few bugs along the way).

---

## 🔄 2. Tween.lua — Interpolation between poses

Generates the in-between frames of two poses, or builds the motion from a single one. It interpolates position, rotation, scale and color, with path curves and easing.

<!-- 🎬 Demo GIF -->
> _(GIF pending)_

**How to use it:**

1. Select the layer to animate (RGB mode) and run the script.
2. Pick the **method**:
   - **Fill between two poses I already drew**: give the start frame (pose A) and end frame (pose B); the script fills the gap.
   - **Create the motion from a single pose**: start from one pose and define the changes with relative values (position, rotation, scale, pivot).
   - **Update an existing tween**: recalculates using the parameters saved on the layer.
3. Pick the **action**: move, fade, or both.
4. Adjust the **timing** (number of frames, duration, easing) and, optionally, the **path** (straight / arc / wave / bounce), the **squash & stretch**, and the **color change** (interpolated in HSL).
5. **OK**: generates the frames.

**Hot update:** the parameters are stored in the layer's metadata (`layer.properties.tween`), so you can re-run with **Update** without configuring everything again.

**Origin:** original work, inspired by **The Tween Machine** (CarbsCode) and **Tweencel** (devkidd).

---

## 💡 3. NormalMap.lua — Normal maps

Generates a normal map from the drawing's alpha contour, so your sprites react to dynamic 2.5D lights in the engine.

<!-- 🎬 Demo GIF -->
> _(GIF pending)_

**How to use it:**

1. With the sprite in RGB mode, run the script.
2. Pick the **scope**:
   - **Layers**: active / selected (range) / all.
   - **Frames**: current / all.
3. Adjust the **relief intensity** (1–63; 32 by default).
4. **OK**: for each source layer it creates/reuses a **`<name>_NormalGenerated`** layer with the normal map.

**Origin:** based on [**ruccho**'s gist](https://gist.github.com/ruccho/2d1eb4aea3dfa55690c2ddc4419172ff), modified and adapted.

---

## 🗺️ Recommended workflow (2.5D pipeline)

1. **Rig and animate** with `Skeleton2Animation` (or draw poses by hand).
2. **Fill/automate** the in-between frames with `Tween`.
3. **Light it**: run `NormalMap` over the frames to generate their normals.
4. **Export** the color sheet and the normal sheet to your engine and enable dynamic 2D lights.

---

## 📄 License

This project is under the **MIT License** ([LICENSE](LICENSE)): use, modify and distribute it for free, in personal or commercial projects.
