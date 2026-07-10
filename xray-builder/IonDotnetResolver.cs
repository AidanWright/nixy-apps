// Registers, at Console startup, the same Amazon.IonDotnet resolver the GUI has
// (XRayBuilder/src/Program.cs) so KFX books load. The DLL's name and identity
// differ, so .NET can't resolve it from deps.json on its own.
using System;
using System.IO;
using System.Reflection;
using System.Runtime.CompilerServices;

internal static class IonDotnetResolver
{
    [ModuleInitializer]
    internal static void Init()
    {
        AppDomain.CurrentDomain.AssemblyResolve += (_, args) =>
            args.Name.StartsWith("Amazon.IonDotnet")
                ? Assembly.LoadFile(Path.Combine(AppContext.BaseDirectory, "Amazon.IonDotnet.Ephemerality.dll"))
                : null;
    }
}
