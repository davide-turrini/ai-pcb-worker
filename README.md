# ai-pcb-worker

Run [ai-pcb](https://github.com/davide-turrini)'s autorouting and simulation **on your own computer**:
unlimited, on every plan, and your boards never wait in a shared queue.

This repository holds what you download: the `ai-pcb-worker` executable for your system (soon), its
install scripts, and the programs it runs, built here from their public sources.

## The tools

`ai-pcb-worker setup` downloads one archive for your system from this repository's releases, checks
it against the checksum pinned in the worker and unpacks it in `~/.ai-pcb-worker/tools`:

| Program | Version | What for | Licence |
|---|---|---|---|
| [Freerouting](https://github.com/freerouting/freerouting) | 2.4.1 | autorouter | GPL-3.0 ([source of 2.4.1](https://github.com/freerouting/freerouting/tree/v2.4.1)) |
| [ngspice](https://ngspice.sourceforge.io) | 44.2 | circuit simulator | Modified BSD |
| [Eclipse Temurin](https://adoptium.net) (reduced with `jlink`) | 25 | runs Freerouting | GPL-2.0 with Classpath Exception |

They are separate programs that the worker starts with files; none of their code is linked into
ai-pcb. The source of each version built here is at its link above;
`scripts/build-tools.sh` and `.github/workflows/tools.yml` say exactly how the archives are made.

Systems: macOS (Apple Silicon and Intel), Linux (x64 and arm64), Windows (x64).
