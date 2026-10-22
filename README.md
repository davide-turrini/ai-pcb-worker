<img src="logo.svg" alt="" width="56" height="56">

# pcbmate-worker

Run [pcbmate](https://github.com/pcbmate)'s autorouting and simulation **on your own computer**:
unlimited, on every plan, and your boards never wait in a shared queue.

This repository holds what you download: the `pcbmate-worker` executable for your system, its
install scripts, and the programs it runs, built here from their public sources.

## Download

The latest version is **0.1.0** ([release notes and checksums](https://github.com/pcbmate/worker-cli/releases/latest)):

| System | Download |
|---|---|
| macOS, Apple Silicon (M1 and later) | [pcbmate-worker-0.1.0-darwin-arm64](https://github.com/pcbmate/worker-cli/releases/download/worker-0.1.0/pcbmate-worker-0.1.0-darwin-arm64) |
| macOS, Intel | [pcbmate-worker-0.1.0-darwin-x64](https://github.com/pcbmate/worker-cli/releases/download/worker-0.1.0/pcbmate-worker-0.1.0-darwin-x64) |
| Windows (x64) | [pcbmate-worker-0.1.0-win32-x64.exe](https://github.com/pcbmate/worker-cli/releases/download/worker-0.1.0/pcbmate-worker-0.1.0-win32-x64.exe) |
| Linux (x64) | [pcbmate-worker-0.1.0-linux-x64](https://github.com/pcbmate/worker-cli/releases/download/worker-0.1.0/pcbmate-worker-0.1.0-linux-x64) |
| Linux (arm64) | [pcbmate-worker-0.1.0-linux-arm64](https://github.com/pcbmate/worker-cli/releases/download/worker-0.1.0/pcbmate-worker-0.1.0-linux-arm64) |

Checksums: [SHA256SUMS](https://github.com/pcbmate/worker-cli/releases/download/worker-0.1.0/SHA256SUMS). The install scripts below download the right one for you,
check it and set it up: the easier way.

## Install

macOS and Linux:

```sh
curl -fsSL https://raw.githubusercontent.com/pcbmate/worker-cli/main/install.sh | sh
```

Windows (PowerShell):

```powershell
irm https://raw.githubusercontent.com/pcbmate/worker-cli/main/install.ps1 | iex
```

The script downloads the executable of the latest version (`latest.json`) for your system, checks it
against the release's `SHA256SUMS`, puts it in `~/.pcbmate-worker/bin` (Windows:
`%LOCALAPPDATA%\pcbmate-worker\bin`, added to your PATH) and runs `setup`, which downloads the tools.
Then, with a token from pcbmate's Workers page:

```sh
pcbmate-worker login <token> --api https://your-pcbmate
pcbmate-worker run        # takes jobs until Ctrl+C; updates itself first when a new version is out
pcbmate-worker update     # or update by hand
pcbmate-worker status
```

Executables are the releases `worker-<version>` (macOS arm64 and x64, Linux x64 and arm64, Windows
x64): a Node.js single executable application with the worker inside. The macOS ones have an ad hoc
signature, so they run when downloaded by the script; Windows may show a SmartScreen warning until
they are signed.

## The tools

`pcbmate-worker setup` downloads one archive for your system from this repository's releases, checks
it against the checksum pinned in the worker and unpacks it in `~/.pcbmate-worker/tools`:

| Program                                                        | Version | What for          | Licence                                                                             |
| -------------------------------------------------------------- | ------- | ----------------- | ----------------------------------------------------------------------------------- |
| [Freerouting](https://github.com/freerouting/freerouting)      | 2.4.1   | autorouter        | GPL-3.0 ([source of 2.4.1](https://github.com/freerouting/freerouting/tree/v2.4.1)) |
| [ngspice](https://ngspice.sourceforge.io)                      | 44.2    | circuit simulator | Modified BSD                                                                        |
| [Eclipse Temurin](https://adoptium.net) (reduced with `jlink`) | 25      | runs Freerouting  | GPL-2.0 with Classpath Exception                                                    |

They are separate programs that the worker starts with files; none of their code is linked into
pcbmate. The source of each version built here is at its link above;
`scripts/build-tools.sh` and `.github/workflows/tools.yml` say exactly how the archives are made.

Systems: macOS (Apple Silicon and Intel), Linux (x64 and arm64), Windows (x64).
