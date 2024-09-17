{pkgs, ...}: {
  packages = with pkgs; [
    pdm
    python3
  ];
}
