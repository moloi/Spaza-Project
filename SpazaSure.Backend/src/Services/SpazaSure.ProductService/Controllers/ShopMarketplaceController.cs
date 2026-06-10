using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SpazaSure.Infrastructure.Data;
using SpazaSure.Shared.Models;

namespace SpazaSure.ProductService.Controllers;

[ApiController]
[Route("api/shop/marketplace")]
[Authorize]
public class ShopMarketplaceController(SpazaSureDbContext db) : ControllerBase
{
    [HttpGet("products")]
    public async Task<IActionResult> Products(
        [FromQuery] int page = 1, [FromQuery] int pageSize = 20,
        [FromQuery] string? search = null, [FromQuery] Guid? categoryId = null,
        [FromQuery] Guid? supplierId = null, [FromQuery] string sort = "popular")
    {
        var query = db.Products
            .Include(p => p.Category).Include(p => p.Supplier)
            .Where(p => p.IsAvailable && p.IsApproved && p.StockQty > 0)
            .Where(p => p.Supplier.Status == "active");

        if (!string.IsNullOrEmpty(search))
            query = query.Where(p => p.Name.Contains(search) || p.Supplier.CompanyName.Contains(search));
        if (categoryId.HasValue)
            query = query.Where(p => p.CategoryId == categoryId);
        if (supplierId.HasValue)
            query = query.Where(p => p.SupplierId == supplierId);

        query = sort switch {
            "price_low" => query.OrderBy(p => p.Price),
            "price_high" => query.OrderByDescending(p => p.Price),
            "newest" => query.OrderByDescending(p => p.CreatedAt),
            _ => query.OrderByDescending(p => p.StockQty)
        };

        var total = await query.CountAsync();
        var items = await query.Skip((page - 1) * pageSize).Take(pageSize)
            .Select(p => new {
                p.Id, p.Name, p.Description, p.Sku, p.Price, p.MinOrderQty,
                p.StockQty, p.Unit, p.Images, p.IsFoodItem,
                CategoryId = p.CategoryId, CategoryName = p.Category != null ? p.Category.Name : null,
                SupplierId = p.SupplierId, SupplierName = p.Supplier.CompanyName,
                SupplierTier = p.Supplier.Tier, SupplierLogo = p.Supplier.LogoUrl,
            }).ToListAsync();

        return Ok(ApiResponse<object>.Ok(new { total, page, pageSize, items }));
    }

    [HttpGet("products/{id:guid}")]
    public async Task<IActionResult> ProductDetail(Guid id)
    {
        var p = await db.Products.Include(x => x.Category).Include(x => x.Supplier)
            .FirstOrDefaultAsync(x => x.Id == id && x.IsAvailable && x.IsApproved);
        if (p is null) return NotFound(ApiResponse.Fail("Product not found."));
        return Ok(ApiResponse<object>.Ok(new {
            p.Id, p.Name, p.Description, p.Sku, p.Price, p.MinOrderQty,
            p.StockQty, p.Unit, p.Images, CategoryName = p.Category?.Name,
            SupplierId = p.SupplierId, SupplierName = p.Supplier.CompanyName,
            SupplierTier = p.Supplier.Tier
        }));
    }

    [HttpGet("categories")]
    public async Task<IActionResult> Categories()
    {
        var items = await db.Set<SpazaSure.Infrastructure.Entities.Category>()
            .Where(c => c.IsActive).OrderBy(c => c.SortOrder)
            .Select(c => new { c.Id, c.Name, c.Slug, c.ParentId, c.IconUrl,
                ProductCount = c.Products.Count(p => p.IsAvailable && p.IsApproved) })
            .ToListAsync();
        return Ok(ApiResponse<object>.Ok(items));
    }

    [HttpGet("suppliers")]
    public async Task<IActionResult> Suppliers()
    {
        var items = await db.Suppliers.Where(s => s.Status == "active")
            .OrderBy(s => s.CompanyName)
            .Select(s => new { s.Id, s.CompanyName, s.Tier, s.LogoUrl, s.City, s.Province,
                ProductCount = s.Products.Count(p => p.IsAvailable && p.IsApproved) })
            .ToListAsync();
        return Ok(ApiResponse<object>.Ok(items));
    }
}
