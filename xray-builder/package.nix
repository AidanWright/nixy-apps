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

  # Upstream targets net6.0, which nixpkgs flags as EOL/insecure. Retarget the
  # build graph to the supported net8.0 runtime.
  postPatch = ''
    find . -name '*.csproj' -exec sed -i 's#<TargetFramework>net6.0</TargetFramework>#<TargetFramework>net8.0</TargetFramework>#g' {} +
  '';

  projectFile = "XRayBuilder.Console/XRayBuilder.Console.csproj";
  nugetDeps = ./deps.json;

  dotnet-sdk = dotnet-sdk_8;
  dotnet-runtime = dotnet-runtime_8;

  executables = [ "XRayBuilder.Console" ];

  meta = {
    description = "Create X-Ray files for Amazon Kindle from Goodreads data";
    homepage = "https://github.com/Ephemerality/xray-builder.gui";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.unix;
    mainProgram = "XRayBuilder.Console";
  };
})
