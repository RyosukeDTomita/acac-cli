# acac-win32-x64

Prebuilt `acac` binary for **win32-x64** (Windows x64).

This is a platform-specific dependency of [`acac-cli`](https://www.npmjs.com/package/acac-cli).
You normally do not install it directly — install `acac-cli` and the matching
platform binary is pulled in automatically as an `optionalDependency`.

```shell
npx acac-cli <atcoder-username>
```

## Build & release transparency

- Built on GitHub Actions from the [acac-cli](https://github.com/RyosukeDTomita/acac-cli) source, on a native Windows runner with GHC 9.12.2 + cabal (linked against the OS's standard system libraries).
- Published automatically by CI with **npm provenance** (`--provenance`, OIDC trusted publishing), so every release is attested back to the exact workflow run and commit.
- Releases are cut from `v*.*.*` tags using GitHub **Immutable Releases** (the release is created by the CI bot, not by hand).

## License

MIT
