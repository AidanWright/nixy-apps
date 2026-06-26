# Packages a prebuilt macOS .app bundle from a downloaded archive into
# $out/Applications/<App>. dmg archives are opened with undmg, zip with unzip.
# Bundles are code-signed by their vendors, so dontFixup keeps them untouched.
{ stdenvNoCC, undmg, unzip }:
{
  pname,
  version,
  src,
  appBundle,
  archive ? "dmg",
}:
stdenvNoCC.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = [ (if archive == "dmg" then undmg else unzip) ];

  sourceRoot = ".";
  unpackPhase = ''
    runHook preUnpack
    ${if archive == "dmg" then ''undmg "$src"'' else ''unzip -q "$src"''}
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/Applications"
    cp -R "${appBundle}" "$out/Applications/"
    runHook postInstall
  '';

  dontFixup = true;
}
