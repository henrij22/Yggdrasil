# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

name = "MuesliMaterialsWrapper"
version = v"0.14.0"


# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/henrij22/libjlmuesli.git", "dcb15bea2ada5fbcd8aa71244e6c0d239bbeb31b")
]

# needed for libjulia_platforms and julia_versions
include("../../L/libjulia/common.jl")

# Bash recipe for building across all platforms
script = raw"""
cd $WORKSPACE/srcdir/libjlmuesli

# atomic_patch -p1 ${WORKSPACE}/srcdir/patches/patch.patch

cmake -B builddir -DCMAKE_INSTALL_PREFIX=$prefix -DJulia_PREFIX=${prefix} -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} -DCMAKE_BUILD_TYPE=Release
cmake --build builddir --parallel ${nprocs}
cmake --install builddir

# if [[ "${target}" == *-mingw* ]]; then
# #cmake install only grabs the .dll.a and leaves the actual .dll behind, manually move it 
# mv builddir/libjlmuesli.dll ${libdir}
# fi
"""

julia_versions = [v"1.10", v"1.11", v"1.12", v"1.13"]
julia_compat = join("~" .* string.(getfield.(julia_versions, :major)) .* "." .* string.(getfield.(julia_versions, :minor)), ", ")

platforms = vcat(libjulia_platforms.(julia_versions)...)

# This can be removed when libcxxwrap_julia_jll supports riscv (does it?)
filter!(p -> !(arch(p) == "riscv64"), platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libjlmuesli", :libjlmuesli)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(; name="libjulia_jll")),
    Dependency("libcxxwrap_julia_jll"; compat="~0.14.7"),
    Dependency(PackageSpec(name="MuesliMaterials_jll", uuid="ef259003-9f3a-5fc7-ae68-dce6b88dc7d6"); compat="1.16")
]


# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat=julia_compat, preferred_gcc_version=v"10")
