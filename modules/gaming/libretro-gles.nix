# Builds RetroArch (frontend + cores) for OpenGL ES, for hosts whose GPU offers
# GLES but not the desktop OpenGL the stock nixpkgs builds expect. Host configs
# read the builders from `config.libretro`.
{ lib, ... }:
let
  # Rebuild a libretro core for GLES instead of desktop GL.
  #
  # Cores that render in hardware request a GL family from the frontend via the
  # `SET_HW_RENDER` environment callback, and mupen64plus-next's GLideN64 RDP
  # plugin asks for a desktop OpenGL 3.3 *core* context. A GLES-only GPU -- the
  # Raspberry Pi 4/400's V3D, which tops out at OpenGL ES 3.1 -- can't provide
  # that, so EGL rejects it (`EGL_BAD_MATCH`) and the core segfaults bringing the
  # renderer up.
  #
  # The core's Makefile already knows how to build for GLES; it needs the switch:
  #
  #   FORCE_GLES3=1 -> Makefile sets GLES3=1
  #                 -> Makefile.common adds -DEGL -DHAVE_OPENGLES
  #                    -DHAVE_OPENGLES3 -DGLES3 and links glsym_es3.c
  #
  # nixpkgs' recipe passes no GL family flags, so its core links libGL; with
  # FORCE_GLES3=1 it links libGLESv2 + libEGL and GLideN64 asks for OpenGL ES 3.
  #
  # Deliberately NOT via `platform=`: the rpi platform targets in that same
  # Makefile discard paraLLEl-RDP/RSP and the angrylion LLE plugin (only rpi5_64
  # sets them), and nixpkgs' mkLibretroCore forces `platform=unix ARCH=arm64` for
  # aarch64 regardless. FORCE_GLES3 is orthogonal -- it changes only the GL
  # family, keeping the full feature set.
  mkGles3Core =
    {
      core,
      gles ? 3,
    }:
    core.overrideAttrs (old: {
      pname = "${old.pname or core.pname}-gles${toString gles}";
      makeFlags = (old.makeFlags or [ ]) ++ [ (if gles == 3 then "FORCE_GLES3=1" else "FORCE_GLES=1") ];
    });

  # Rebuild a core with the paraLLEl-RDP/RSP code paths left OUT.
  #
  # nixpkgs' mupen64plus recipe hardcodes
  #
  #   makeFlags = [ "HAVE_PARALLEL_RDP=1" "HAVE_PARALLEL_RSP=1" ... ]
  #
  # so every core it builds carries the Vulkan/paraLLEl renderer and RSP
  # integration even when nothing selects them at runtime. The upstream Makefile
  # guards both with `?=` (Makefile:5-6), so a command-line `=0` wins and the
  # feature is compiled out entirely.
  #
  # Why this can matter for audio: with paraLLEl-RSP compiled in, the core
  # silently falls back to it ("Selected HLE RSP with Angrylion, falling back to
  # Parallel RSP!"), which brings a Vulkan compute renderer and its own worker
  # threads into the process. Compiled out, angrylion runs on cxd4 or HLE alone,
  # so the core's threading and audio-list delivery change.
  #
  # This is NOT a pure dead-code removal: dropping HAVE_PARALLEL_RSP removes a
  # renderer option the stock build can actively use.
  mkLeanCore =
    {
      core,
      parallelRdp ? false,
      parallelRsp ? false,
      thrAl ? true,
      lle ? true,
    }:
    let
      flag = name: value: "${name}=${if value then "1" else "0"}";
    in
    core.overrideAttrs (old: {
      pname = "${old.pname or core.pname}-lean";
      makeFlags =
        (old.makeFlags or [ ])
        ++ [
          (flag "HAVE_PARALLEL_RDP" parallelRdp)
          (flag "HAVE_PARALLEL_RSP" parallelRsp)
          (flag "HAVE_THR_AL" thrAl)
          (flag "LLE" lle)
        ];
    });

  # Rebuild the frontend for GLES instead of desktop GL.
  #
  # RetroArch picks its GL family at COMPILE time and the two are mutually
  # exclusive: runloop.c's dynamic_request_hw_context() is guarded by
  # `#if defined(HAVE_OPENGLES)` / `#elif defined(HAVE_OPENGL) ||
  # defined(HAVE_OPENGL_CORE)`, and each branch rejects the other family's
  # request at runtime:
  #
  #   desktop build: "Requesting OpenGLES3 context, but RetroArch is compiled
  #                   against OpenGL. Cannot use HW context."
  #   GLES build:    "Requesting OpenGL context, but RetroArch is compiled
  #                   against OpenGLES. Cannot use HW context."
  #
  # So on a GLES-only GPU even a GLES-rebuilt core still fails -- the frontend
  # refuses first. Both halves must be rebuilt.
  #
  # These flags are the ones Libretro documents for the Pi 4
  # (docs.libretro.com/guides/rpi). They MUST be configureFlags, not makeFlags:
  # HAVE_OPENGLES3/HAVE_OPENGL_CORE are decided by qb/config.libs.sh, which keeps
  # HAVE_OPENGL_CORE on when HAVE_OPENGLES3 is on -- so gl3.o (the driver cores
  # actually use) IS still built, but glsym.h routes it to the ES3 symbol table
  # (glsym_es3.h) rather than the desktop one. Passing them as make variables
  # leaves OPENGL_LIBS unset in the GLES branch of Makefile.common while gl3.o is
  # still compiled, and the link dies on
  # `undefined reference to symbol 'glColorMask'`.
  # The GLES frontend additionally needs two patches, because upstream does not
  # support an ES3-without-ES2 build (which is exactly what --enable-opengles3
  # with --disable-opengl1 produces).
  #
  # Makefile.common defines HAVE_OPENGLES3 XOR HAVE_OPENGLES2 -- the ES3 branch
  # is an `else` away from the ES2 one, never both. But wayland_ctx.c reaches for
  # the ES2-guarded egl_attribs_gles array as its fallback:
  #
  #   #ifdef HAVE_OPENGLES3
  #   #ifdef EGL_KHR_create_context
  #      if (g_egl_major >= 3) attrib_ptr = egl_attribs_gles3;
  #      else                                     <-- compiled out, NULL stays
  #   #endif
  #   #ifdef HAVE_OPENGLES2
  #      attrib_ptr = egl_attribs_gles;           <-- compiled out
  #   #endif
  #
  # attrib_ptr is initialised to NULL, and egl_init_context()'s HAVE_DYLIB
  # attribute scan dereferences it at egl_common.c:639:
  #
  #   for (; *attrib_ptr != EGL_NONE; ++attrib_ptr)
  #
  # -> SIGSEGV. Content load passes major=3 (the core requests GLES3) and works;
  # the MENU passes major=2 and crashes. That asymmetry is what made the kiosk
  # die on boot but launch games fine.
  #
  # 0001 makes the ES3 branch always use the ES3 array (an ES3 config satisfies
  # an ES2 request), and 0002 adds the missing NULL guard so this class of bug
  # degrades to an error message instead of a segfault.
  gles3Patches = [
    ./patches/0001-gfx-wayland-fix-null-attribs.patch
    ./patches/0002-egl-guard-null-attribs.patch
  ];
  mkGles3Bare =
    {
      pkgs,
      retroarch-bare ? pkgs.retroarch-bare,
      gles ? 3,
      patches ? gles3Patches,
    }:
    retroarch-bare.overrideAttrs (old: {
      pname = "${old.pname or "retroarch-bare"}-gles${toString gles}";
      configureFlags = (old.configureFlags or [ ]) ++ [
        "--enable-opengles"
        "--enable-opengles${toString gles}"
        "--enable-opengles${toString gles}_1"
        "--disable-opengl1"
      ];
      patches = (old.patches or [ ]) ++ patches;
    });
  mkGles3Frontend =
    {
      pkgs,
      retroarch-bare ? pkgs.retroarch-bare,
      gles ? 3,
      cores ? [ ],
      settings ? { },
    }:
    let
      gles3Bare = mkGles3Bare { inherit pkgs retroarch-bare gles; };
    in
    # Call wrapper.nix DIRECTLY rather than `retroarch-bare.passthru.wrapper`.
    # passthru.wrapper is defined inside retroarch-bare/package.nix and closes
    # over THAT package's own `retroarch-bare` argument, so `gles3Bare.wrapper`
    # inherits the original's passthru and silently symlinks the STOCK binary
    # back into the wrapper (the output looks fine until you resolve the
    # symlinks and find the desktop-GL build). wrapper.nix takes retroarch-bare
    # as a real argument, so importing it is the only correct injection point.
    import "${pkgs.path}/pkgs/by-name/re/retroarch-bare/wrapper.nix" {
      inherit (pkgs)
        lib
        libretro
        makeBinaryWrapper
        writeText
        symlinkJoin
        ;
      retroarch-bare = gles3Bare;
      inherit cores;
      settings = {
        assets_directory = "${pkgs.retroarch-assets}/share/retroarch/assets";
        joypad_autoconfig_dir = "${pkgs.retroarch-joypad-autoconfig}/share/libretro/autoconfig";
        libretro_info_path = "${pkgs.libretro-core-info}/share/retroarch/cores";
      }
      // settings;
    };
in
{
  flake.modules.nixos.libretro-gles =
    { lib, ... }:
    {
      options.libretro = lib.mkOption {
        internal = true;
        readOnly = true;
        default = {
          inherit mkGles3Core mkLeanCore mkGles3Bare mkGles3Frontend;
        };
        description = "Builders for OpenGL ES variants of RetroArch and its cores.";
      };
    };
}
