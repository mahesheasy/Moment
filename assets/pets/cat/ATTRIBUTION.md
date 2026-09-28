# `cat.glb` (development placeholder)

The bundled `cat.glb` is currently the **Khronos glTF Sample Fox** model
(downloaded from the official Khronos glTF Sample Assets repository).

- License: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)
- Source: https://github.com/KhronosGroup/glTF-Sample-Assets/tree/main/Models/Fox

It is a **temporary rigged stand-in** so 3D rendering and animations work in the app
while you source or author a stylized **cat** model for Moment.

## Replace with your Moment cat

1. Export `cat.glb` from Blender (or your DCC) with these animation clips
   (names are flexible; the app maps logical names to clips):
   - Idle, Walk, Run, Eat, Drink, Sleep, Wake, Play, Happy, Sad, Celebrate
2. Overwrite `assets/pets/cat/cat.glb`
3. Run `flutter pub get` and rebuild the app

## Free cat sources (CC0)

- [Quaternius Ultimate Animated Animal Pack](https://quaternius.com/packs/ultimateanimatedanimals.html) (includes Cat, many animations)
- [Quaternius Cat on Poly Pizza](https://poly.pizza/m/qKICY6xla2)

After replacing the file, delete or update this attribution file if the new asset requires different credits.
