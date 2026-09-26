# Per-architecture facts for the guest builds (runyaga#1).
#
# The guest assets build natively: an x86_64-linux host builds the
# amd64 guest, an aarch64-linux host the arm64 one — cloud-hypervisor
# runs a guest of the host's own architecture under KVM, so the
# build host's system names the guest's. Every fact that differs by
# architecture lives in this one table, keyed by nix system: the
# upstream artifacts (URL fragment plus digest, the same pins the
# builds used before the table existed), the names the images bake
# in (Debian's arch and multiarch triplet, the ELF loader, the
# serial console device), and the kernel-side module differences.
# A system without an entry fails at evaluation time.
{ stdenv }:

let
  platforms = {
    x86_64-linux = {
      # Debian's architecture name: the cloud image, the kernel
      # flavor, and the deb filenames all carry it; the OCI image
      # config records it too.
      debianArch = "amd64";
      multiarch = "x86_64-linux-gnu";
      loader = "/lib64/ld-linux-x86-64.so.2";
      # The 8250 UART cloud-hypervisor emulates on x86.
      serialConsole = "ttyS0";
      # bzImage with the PVH entry point (CONFIG_PVH=y) — what
      # cloud-hypervisor's x86 direct boot takes.
      kernelFormat = "bzImage";
      # The cloud image's root partition type GUID (the
      # Discoverable Partitions Specification's per-architecture
      # "Linux root" type).
      rootPartitionType = "4F68BCE3-E8CD-4DB1-96E7-FBCAF984B709";
      # The platform-specific modules the runtime closure carries:
      # the x86cpu hardware crc32c ext4's metadata_csum asks the
      # crypto API for, and the nested-KVM pair (kvm and its deps
      # ride in through modprobe). The ACPI power button's `button`
      # module is in the shared list.
      platformModules = [
        "crc32c-intel"
        "kvm-intel"
        "kvm-amd"
      ];
      kvmModprobe = "modprobe kvm-intel || modprobe kvm-amd || true";
      debianImage = {
        name = "debian-13-genericcloud-amd64-20260831-2587.qcow2";
        hash = "sha512:8ea9faae810043a0b35b0149f05014f26705c2339ffb11ead308f33e844a87cc3ef46ec81d5262b38817b6a88af404874d48a5857ebe072ef6a31dfb6e371f50";
      };
      kernelDeb = {
        name = "linux-image-6.12.107+deb13-amd64-unsigned_6.12.107-1_amd64.deb";
        hash = "sha256-fRPNgqHTd+QIJsMT9du9su3xtIxxOjdeTP5eIHdJy04=";
      };
      rsyncDeb = {
        name = "rsync_3.4.1+ds1-5+deb13u4_amd64.deb";
        hash = "sha256-iqEi9rqNL/ESxyu5gU7glu5RbwITs2uYu+ecg8kvsiY=";
      };
      fdFindDeb = {
        name = "fd-find_10.2.0-1+b5_amd64.deb";
        hash = "sha256-FVTGiS23vhDUxr2/GfetQXKCahttAeXMU3uB1rAttNE=";
      };
      ripgrepDeb = {
        name = "ripgrep_14.1.1-1+b4_amd64.deb";
        hash = "sha256-fgwyUQwmTDEzX+O5rjerdtzSL30WJ6CghRilvyixesI=";
      };
      nodeTarball = {
        name = "node-v22.23.3-linux-x64.tar.gz";
        hash = "sha256-EISqNhlrukw6Xmmh7jiKbk/3KdrQlEX7zUNLKP48JK8=";
      };
      # Claude Code's native-binary npm package for this platform.
      claudePlatform = "linux-x64";
      claudeBinary = {
        name = "claude-code-linux-x64-2.1.281.tgz";
        hash = "sha256-sNo8XYzhnBCEmFvKLkmqTG54rQYGwrSsfeYH2aMd10o=";
      };
      herdrBinary = {
        name = "v0.9.1/herdr-linux-x86_64";
        hash = "sha256-KgL+0WvrZR7wBuHUPwSPZSyk3FitBTzS1ERQVj1cVLc=";
      };
    };

    aarch64-linux = {
      debianArch = "arm64";
      multiarch = "aarch64-linux-gnu";
      loader = "/lib/ld-linux-aarch64.so.1";
      # The PL011 UART cloud-hypervisor emulates on aarch64.
      serialConsole = "ttyAMA0";
      # The arm64 boot Image (Debian ships it uncompressed as
      # vmlinuz) — what cloud-hypervisor's aarch64 direct boot takes.
      kernelFormat = "Image";
      rootPartitionType = "B921B045-1DF0-41C3-AF44-4C6F280D3FAE";
      # KVM is built into the arm64 kernel (CONFIG_KVM=y) and the
      # crc32c instructions serve the crypto API without a module.
      # The power button differs: cloud-hypervisor's aarch64 guest
      # gets it as a GPIO key on the PL061 (a device-tree
      # gpio-keys node), not an ACPI button, and gpio_keys is a
      # module in Debian's arm64 kernel — without it the host's
      # graceful-shutdown press never reaches logind (#25).
      platformModules = [ "gpio_keys" ];
      kvmModprobe = "true";
      debianImage = {
        name = "debian-13-genericcloud-arm64-20260831-2587.qcow2";
        hash = "sha512:321adcf21b6d2941e09e96f333af0c8f35b0865904834a4eb8149cfd2286b902d4868494ddfc863052a3267886533796aa3e21db24a243c0fc56a49c753471be";
      };
      kernelDeb = {
        name = "linux-image-6.12.107+deb13-arm64-unsigned_6.12.107-1_arm64.deb";
        hash = "sha256-L5hq3hoTNkI63yMW6onDUl3UwFpkayFBYmSQyi84gzk=";
      };
      rsyncDeb = {
        name = "rsync_3.4.1+ds1-5+deb13u4_arm64.deb";
        hash = "sha256-Z+t85goFbiO4bArAIPwA2mJkf9v740RTaTYB+Nsavyk=";
      };
      fdFindDeb = {
        name = "fd-find_10.2.0-1+b5_arm64.deb";
        hash = "sha256-8pYF6zpjMDr5Qf0tjp9ArQwNLD9GCJUiw5EyaA5tGbg=";
      };
      ripgrepDeb = {
        name = "ripgrep_14.1.1-1+b4_arm64.deb";
        hash = "sha256-m080e6IyCyLLohfMSweFNllsxqFAnfAB/FYK0/o5Zgk=";
      };
      nodeTarball = {
        name = "node-v22.23.3-linux-arm64.tar.gz";
        hash = "sha256-XO0tSNHXGYc5t/hoBN4Bca77aCO2hLEjQdMyGvw8sLI=";
      };
      claudePlatform = "linux-arm64";
      claudeBinary = {
        name = "claude-code-linux-arm64-2.1.281.tgz";
        hash = "sha256-+Y9om+Ie9zQozNusulYaFMVrv1SgaQWjWvbdWYF8v3o=";
      };
      herdrBinary = {
        name = "v0.9.1/herdr-linux-aarch64";
        hash = "sha256-9Mz03nRfLLmjmpg+m6NwPa1Q7CpY3qgwJs6rchu9jZ4=";
      };
    };
  };

  system = stdenv.hostPlatform.system;
in
platforms.${system}
  or (throw "msks guest: no guest platform facts for ${system} (nix/guest-platform.nix)")
// {
  inherit system;
}
