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

// 2. DI
builder.Services.AddScoped<IProductRepository, ProductRepository>();
builder.Services.AddScoped<IProductService, ProductService>();

// 🚀 CORS — CHO PHÉP GỌI TỪ ĐIỆN THOẠI
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod());
});

// 3. ADD MVC/API
builder.Services.AddControllersWithViews();

var app = builder.Build();

// PIPELINE
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

// app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

// 🚀 BẬT CORS
app.UseCors("AllowAll");

app.UseAuthorization();

// API route + MVC route
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
