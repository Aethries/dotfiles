{ pkgs, ... }:

{
  # Keep the editor, runtime and matching export templates on the same pinned
  # nixpkgs revision. Godot provides its own GDScript LSP and DAP servers.
  environment.systemPackages = with pkgs; [
    godot
    godot-export-templates-bin
    godot-mcp
    godotpcktool
  ];

  # system-path does not link /share/godot by default. Expose the templates at
  # /run/current-system/sw so sync-editors.sh can create the per-user link Godot
  # expects under XDG_DATA_HOME.
  environment.pathsToLink = [ "/share/godot" ];
}
