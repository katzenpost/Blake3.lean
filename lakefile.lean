import Lake

open Lake DSL

package Blake3

lean_lib Blake3

require YatimaStdLib from git
  "https://github.com/yatima-inc/YatimaStdLib.lean" @ "10f2b444390a41ede90ca5c038c6ff972014d433"

def ffiC := "ffi.c"
def ffiO := "ffi.o"

target importTarget pkg : FilePath := do
  let oFile := pkg.irDir / ffiO
  let srcJob ← inputFile <| pkg.dir / "C" / "ffi.c"
  buildFileAfterDep oFile srcJob fun srcFile => do
    let flags := #["-I", (← getLeanIncludeDir).toString, "-fPIC"]
    compileO oFile srcFile flags

extern_lib ffi pkg := do
  let job ← fetch <| pkg.target ``importTarget
  let libFile := pkg.nativeLibDir / nameToStaticLib "ffi"
  buildStaticLib libFile #[job]

extern_lib rust_ffi pkg := do
  proc { cmd := "cargo", args := #["build", "--release"], cwd := pkg.dir }
  let name := nameToStaticLib "rust_ffi"
  let srcPath := pkg.dir / "target" / "release" / name
  IO.FS.createDirAll pkg.nativeLibDir
  let tgtPath := pkg.nativeLibDir / name
  IO.FS.writeBinFile tgtPath (← IO.FS.readBinFile srcPath)
  return (pure tgtPath)
