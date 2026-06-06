## Quick Start

**Hardware**
- **Minimum:** 8 GB RAM, 4-core x86 or ARM64, 20 GB free disk (3B Q4 model, CPU-only)
- **Recommended:** 16 GB+ RAM, 8+ cores, SSD (7B+ models, ChromaDB, SearXNG, ntfy)
- **GPU:** NVIDIA (CUDA 12+) or AMD (ROCm 6+) for Cookbook local serving; Metal on Apple Silicon via native macOS install

Defaults work out of the box: clone, run, then configure models/search/email
inside **Settings**. Only edit `.env` for deployment-level overrides like
`APP_BIND`, `APP_PORT`, `AUTH_ENABLED`, `DATABASE_URL`, or a pre-seeded admin password.

On first setup, Odysseus creates an admin account (`admin` unless
`ODYSSEUS_ADMIN_USER` is set) and prints a temporary password in the terminal.
For Docker installs, the same line is in `docker compose logs odysseus`.
Use that for the first login, then change it in **Settings**.

Contributing? See [CONTRIBUTING.md](CONTRIBUTING.md) for setup, testing, and
pull request guidelines.

### Docker (recommended)
  
