{ ... }:

{
  # ============================================================
  # Swap Configuration & Memory Management
  # ============================================================

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 32 * 1024; # 32 GiB (32768 MiB)
      priority = 10;
    }
  ];

  # Tối ưu hóa việc sử dụng swap khi hệ thống có 32GB RAM
  boot.kernel.sysctl = {
    "vm.swappiness" = 10; # Chỉ swap khi bộ nhớ thực sự thiếu
    "vm.vfs_cache_pressure" = 50; # Giữ lại cache thư mục và inode trong RAM lâu hơn
  };
}
