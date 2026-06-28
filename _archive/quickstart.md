# okl Quickstart

## Prerequisites

- Ubuntu 24.04 LTS build machine
- `make`, `bash`, `curl`
- SSH access to target node

## 1. Clone

```bash
git clone https://github.com/openkubes/ok-linux.git
cd ok-linux
```

## 2. Build Golden Image

```bash
make image
# Output: build/okl-v0.1.0-amd64.img
```

## 3. Build Kernel (optional)

```bash
make kernel
# Output: build/linux-6.8.0/arch/x86/boot/bzImage
```

## 4. Install on Node

```bash
make install NODE=ok-infra
```

## 5. Deploy OKE on top of okl

```bash
cd ../ok-rke2
make install
```

## Hetzner Bare Metal

See [docs/hetzner.md](hetzner.md) for Hetzner-specific setup.

## Cloud-init

Customize `image/cloud-init/user-data.yaml` before building:

```yaml
users:
  - name: okl
    ssh_authorized_keys:
      - ssh-ed25519 AAAA... your-key
```
