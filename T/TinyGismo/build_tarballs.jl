# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder, Pkg

# See https://github.com/JuliaLang/Pkg.jl/issues/2942
# Once this Pkg issue is resolved, this must be removed
uuid = Base.UUID("a83860b7-747b-57cf-bf1f-3e79990d037f")
delete!(Pkg.Types.get_last_stdlibs(v"1.6.3"), uuid)

name = "TinyGismo"
version = v"0.1.11"


# Collection of sources required to complete build
sources = [
    GitSource("https://github.com/henrij22/libjltinygismo", "6786b273d30842db88ae0b1cdd66bf510ee96e45")
]

# needed for libjulia_platforms and julia_versions
include("../../L/libjulia/common.jl")

# Bash recipe for building across all platforms
script = raw"""

cd $WORKSPACE/srcdir/libjltinygismo
export LDFLAGS="-L${libdir}"
cmake -B builddir \
        -DCMAKE_INSTALL_PREFIX=${prefix} \
        -DJulia_PREFIX=${prefix} \
        -Dgismo_DIR=${WORKSPACE}/destdir/lib/cmake \
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
        -DCMAKE_BUILD_TYPE=Release
cmake --build builddir --parallel ${nprocs}
cmake --install builddir


# if [[ "${target}" == *-mingw* ]]; then
# #cmake install only grabs the .dll.a and leaves the actual .dll behind, manually move it 
# mv builddir/libjltinygismo.dll ${libdir}
# fi
"""

julia_versions = [v"1.11", v"1.12", v"1.13"]
julia_compat = join("~" .* string.(getfield.(julia_versions, :major)) .* "." .* string.(getfield.(julia_versions, :minor)), ", ")

platforms = vcat(libjulia_platforms.(julia_versions)...)

# This can be removed when libcxxwrap_julia_jll supports riscv (does it?)
filter!(p -> !(arch(p) == "riscv64"), platforms)
platforms = expand_cxxstring_abis(platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libjltinygismo", :libjltinygismo)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    BuildDependency(PackageSpec(; name="libjulia_jll")),
    Dependency("libcxxwrap_julia_jll"; compat="~0.14.7"),
    Dependency("gismo_jll"; compat="~25.7.0"),
]


# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat=julia_compat, preferred_gcc_version=v"10")