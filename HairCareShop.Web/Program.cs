using HairCareShop.Core.Interfaces;
using HairCareShop.Data.EF;
using HairCareShop.Data.Repositories;
using HairCareShop.Service.Interfaces;
using HairCareShop.Service.Services;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

// 1. KẾT NỐI SQL SERVER
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<HairCareShopDbContext>(options =>
    options.UseSqlServer(connectionString));

// 2. ĐĂNG KÝ DI (DEPENDENCY INJECTION) - QUAN TRỌNG
// (Khi Controller cần IProductRepository, hệ thống sẽ đưa ProductRepository)
builder.Services.AddScoped<IProductRepository, ProductRepository>();
builder.Services.AddScoped<IProductService, ProductService>();

// 3. Add services to the container.
builder.Services.AddControllersWithViews();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthorization();

// Định nghĩa route cho MVC và API
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();