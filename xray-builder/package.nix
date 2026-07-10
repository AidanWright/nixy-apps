{
  lib,
  buildDotnetModule,
  dotnet-sdk_8,
  dotnet-runtime_8,
  fetchFromGitHub,
}:
buildDotnetModule (finalAttrs: {
  pname = "xray-builder";
  version = "2.1.200";

  src = fetchFromGitHub {
    owner = "Ephemerality";
    repo = "xray-builder.gui";
    rev = finalAttrs.version;
    hash = "sha256-BlrdiSSWaSpM8SKae9utn0XNVzUNW4fu3r84Htg8XqQ=";
  };

  # Retarget net6.0 (EOL/insecure in nixpkgs) to net8.0, and drop in a module
  # initializer that resolves Amazon.IonDotnet at startup (see the .cs comment).
  postPatch = ''
    find . -name '*.csproj' -exec sed -i 's#<TargetFramework>net6.0</TargetFramework>#<TargetFramework>net8.0</TargetFramework>#g' {} +
    cp ${./IonDotnetResolver.cs} XRayBuilder.Console/IonDotnetResolver.cs
  '';

  projectFile = "XRayBuilder.Console/XRayBuilder.Console.csproj";
  nugetDeps = ./deps.json;

  dotnet-sdk = dotnet-sdk_8;
  dotnet-runtime = dotnet-runtime_8;

  executables = [ "XRayBuilder.Console" ];

  # dotnet publish drops the HintPath'd Amazon.IonDotnet DLL; ship it so the
  # startup resolver can load it by path.
  postInstall = ''
    cp lib/Ephemerality.Unpack/Amazon.IonDotnet.Ephemerality.dll \
      "$out/lib/xray-builder/Amazon.IonDotnet.Ephemerality.dll"
  '';

  meta = {
    description = "Create X-Ray files for Amazon Kindle from Goodreads data";
    homepage = "https://github.com/Ephemerality/xray-builder.gui";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.unix;
    mainProgram = "XRayBuilder.Console";
  };
})
