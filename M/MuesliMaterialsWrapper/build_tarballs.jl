# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

name = "MuesliMaterialsWrapper"
version = v"1.0.1"


# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/henrij22/libjlmuesli.git", "0ac882e83594ee266b3e6eb90ae865256993d210")
]

julia_versions = [v"1.11", v"1.12", v"1.13", v"1.14"]

# needed for libjulia_platforms
include("../../L/libjulia/common.jl")

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libjlmuesli

# atomic_patch -p1 ${WORKSPACE}/srcdir/patches/patch.patch

cmake -B builddir -DCMAKE_INSTALL_PREFIX=$prefix -DJulia_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release -DJLMUESLI_BUILD_TESTS=OFF
cmake --build builddir --parallel ${nprocs}
cmake --install builddir
"""

platforms = vcat(libjulia_platforms.(julia_versions)...)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libjlmuesli", :libjlmuesli)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(; name="libjulia_jll")),
    Dependency("libcxxwrap_julia_jll"; compat="~0.14.12"),
    Dependency("MuesliMaterials_jll"; compat="~2.0.0"),
]


# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat=libjulia_julia_compat(julia_versions), preferred_gcc_version=v"10")
