using HairCareShop.Core.Entities;
using Microsoft.EntityFrameworkCore;

namespace HairCareShop.Data.EF
{
    public class HairCareShopDbContext : DbContext
    {
        public HairCareShopDbContext(DbContextOptions<HairCareShopDbContext> options) : base(options) { }

        public DbSet<Product> Products { get; set; }
        public DbSet<Category> Categories { get; set; }
        public DbSet<User> Users { get; set; }
        public DbSet<Order> Orders { get; set; }
        public DbSet<OrderDetail> OrderDetails { get; set; }
        public DbSet<ProductImage> ProductImages { get; set; }

        // --- KHAI BÁO THÊM CÁC BẢNG NÀY ---
        public DbSet<Supplier> Suppliers { get; set; }
        public DbSet<ProductBatch> ProductBatches { get; set; }
        public DbSet<ImportNote> ImportNotes { get; set; }
        public DbSet<ImportNoteDetail> ImportNoteDetails { get; set; }
    }
}