import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_rust/native_toolchain_rust.dart';

// Builds the Rust crate in rust/ for the target platform. Flutter bundles
// the result as a dynamic library on every platform (a framework on
// iOS/macOS), so it never clashes with other Rust libraries in the app the
// way two force-loaded static libraries would.
void main(List<String> args) async {
  await build(args, (input, output) async {
    await const RustBuilder(
      assetName: 'src/rust/frb_generated.io.dart',
    ).run(input: input, output: output);

    // Flutter only reruns this hook when a listed dependency changes, and
    // would otherwise keep pointing at a built library that has since been
    // deleted (e.g. by an interrupted cargo run). Listing the library itself
    // makes a missing or changed file trigger a rebuild. Cargo's dep-info
    // leaves out the manifest and lockfile, so list those too.
    output.dependencies.addAll([
      input.packageRoot.resolve('rust/Cargo.toml'),
      input.packageRoot.resolve('rust/Cargo.lock'),
      input.packageRoot.resolve('../blastqr_envelope/Cargo.toml'),
      for (final asset in output.build().assets.encodedAssets)
        if (asset.isCodeAsset && asset.asCodeAsset.file != null)
          asset.asCodeAsset.file!,
    ]);
  });
}
