# fh2-nvk

NVK (the Mesa Vulkan driver) for Nintendo Switch homebrew, built with the patches used by the FH2 NX port
(NXMASTER-Ascencion H.O). No game files: only build scripts and driver patches.

- Mesa for Switch: [danfromtico/mesa-switch](https://github.com/danfromtico/mesa-switch) (MIT and others, see Mesa).
- Build script: [nebadasSwifty/masseffect-nx](https://github.com/nebadasSwifty/masseffect-nx) (`mesa/build_mesa_docker.sh`).
- Switch patch: [penettrator/prototype2-nx](https://github.com/penettrator/prototype2-nx) (`patches/mesa-switch.patch`, GPL-3.0).
- `patches/fh2-nvk.patch`: lighter barriers on request of the app (`nvk_fh2_barreras`): see the comment in the patch.

The `nvk` workflow builds `out/mesa-sdk` in Docker (devkitpro/devkita64) and publishes it as a release asset.
