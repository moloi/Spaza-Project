using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SpazaSure.Infrastructure.Data;
using SpazaSure.Infrastructure.Entities;
using SpazaSure.ProductService.Services;
using SpazaSure.Shared.Models;
using System.ComponentModel.DataAnnotations;
using System.Security.Claims;

namespace SpazaSure.ProductService.Controllers;

[ApiController]
[Route("api/supplier/products")]
[Authorize]
public class ProductsController(SpazaSureDbContext db) : ControllerBase
{
    private Guid SupplierId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    [HttpGet]
    public async Task<IActionResult> List([FromQuery] int page = 1, [FromQuery] int pageSize = 20,
        [FromQuery] string? search = null, [FromQuery] string? status = null)
    {
        var supplier = await db.Suppliers.FirstOrDefaultAsync(s => s.UserId == SupplierId);
        if (supplier is null) return Ok(ApiResponse<object>.Ok(new { total = 0, page, pageSize, items = Array.Empty<object>() }));

        var query = db.Products
            .Include(p => p.Category)
            .Where(p => p.SupplierId == supplier.Id);

        if (!string.IsNullOrEmpty(search))
            query = query.Where(p => p.Name.Contains(search) || p.Sku.Contains(search));

        if (status == "active") query = query.Where(p => p.IsAvailable && p.IsApproved);
        else if (status == "pending_approval") query = query.Where(p => !p.IsApproved);
        else if (status == "archived") query = query.Where(p => !p.IsAvailable && p.IsApproved);

        var total = await query.CountAsync();
        var items = await query
            .OrderByDescending(p => p.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(p => new {
                p.Id, p.Name, p.Sku, p.Price, p.StockQty, p.Unit,
                p.IsAvailable, p.IsApproved, p.Images, p.Description,
                p.MinOrderQty, p.IsFoodItem, p.CategoryId,
                Category = p.Category == null ? null : p.Category.Name,
                p.CreatedAt
            })
            .ToListAsync();

        return Ok(ApiResponse<object>.Ok(new { total, page, pageSize, items }));
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Get(Guid id)
    {
        var supplier = await db.Suppliers.FirstOrDefaultAsync(s => s.UserId == SupplierId);
        if (supplier is null) return NotFound(ApiResponse.Fail("Supplier not found."));

        var product = await db.Products.Include(p => p.Category)
            .FirstOrDefaultAsync(p => p.Id == id && p.SupplierId == supplier.Id);
        if (product is null) return NotFound(ApiResponse.Fail("Product not found."));

        return Ok(ApiResponse<Product>.Ok(product));
    }

    [HttpPost]
    public async Task<IActionResult> Create(ProductRequest req)
    {
        var supplier = await db.Suppliers.FirstOrDefaultAsync(s => s.UserId == SupplierId);
        if (supplier is null) return NotFound(ApiResponse.Fail("Supplier not found."));

        var product = new Product
        {
            SupplierId = supplier.Id,
            CategoryId = req.CategoryId,
            Name = req.Name,
            Description = req.Description,
            Sku = req.Sku,
            Barcode = req.Barcode,
            Price = req.Price,
            MinOrderQty = req.MinOrderQty,
            StockQty = req.StockQty,
            Unit = req.Unit,
            Images = req.Images ?? "[]",
            IsAvailable = req.IsAvailable,
            IsFoodItem = req.IsFoodItem
        };
        db.Products.Add(product);
        await db.SaveChangesAsync();

        // Auto-generate EAN-13 barcode if not supplied
        if (string.IsNullOrEmpty(product.Barcode))
        {
            product.Barcode = BarcodeService.GenerateEan13(product.Id);
            await db.SaveChangesAsync();
        }

        return Ok(ApiResponse<object>.Ok(new
        {
            product.Id, product.Name, product.Sku, product.Barcode,
            product.Price, product.StockQty, product.IsAvailable, product.IsApproved
        }));
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, ProductRequest req)
    {
        var supplier = await db.Suppliers.FirstOrDefaultAsync(s => s.UserId == SupplierId);
        if (supplier is null) return NotFound(ApiResponse.Fail("Supplier not found."));

        var product = await db.Products.FirstOrDefaultAsync(p => p.Id == id && p.SupplierId == supplier.Id);
        if (product is null) return NotFound(ApiResponse.Fail("Product not found."));

        product.CategoryId = req.CategoryId;
        product.Name = req.Name;
        product.Description = req.Description;
        product.Sku = req.Sku;
        product.Barcode = req.Barcode;
        product.Price = req.Price;
        product.MinOrderQty = req.MinOrderQty;
        product.StockQty = req.StockQty;
        product.Unit = req.Unit;
        product.Images = req.Images ?? product.Images;
        product.IsAvailable = req.IsAvailable;
        product.IsFoodItem = req.IsFoodItem;

        await db.SaveChangesAsync();
        return Ok(ApiResponse<Product>.Ok(product));
    }

    [HttpPatch("{id:guid}/toggle")]
    public async Task<IActionResult> Toggle(Guid id)
    {
        var supplier = await db.Suppliers.FirstOrDefaultAsync(s => s.UserId == SupplierId);
        if (supplier is null) return NotFound(ApiResponse.Fail("Supplier not found."));

        var product = await db.Products.FirstOrDefaultAsync(p => p.Id == id && p.SupplierId == supplier.Id);
        if (product is null) return NotFound(ApiResponse.Fail("Product not found."));

        product.IsAvailable = !product.IsAvailable;
        await db.SaveChangesAsync();
        return Ok(ApiResponse<object>.Ok(new { product.Id, product.IsAvailable }));
    }

    [HttpGet("{id:guid}/barcode")]
    public async Task<IActionResult> GetBarcode(Guid id)
    {
        var supplier = await db.Suppliers.FirstOrDefaultAsync(s => s.UserId == SupplierId);
        if (supplier is null) return NotFound(ApiResponse.Fail("Supplier not found."));

        var product = await db.Products
            .FirstOrDefaultAsync(p => p.Id == id && p.SupplierId == supplier.Id);
        if (product is null) return NotFound(ApiResponse.Fail("Product not found."));

        // Generate barcode if missing (legacy products)
        if (string.IsNullOrEmpty(product.Barcode))
        {
            product.Barcode = BarcodeService.GenerateEan13(product.Id);
            await db.SaveChangesAsync();
        }

        var svg = BarcodeService.RenderSvg(product.Barcode);

        return Ok(ApiResponse<object>.Ok(new
        {
            productId   = product.Id,
            productName = product.Name,
            sku         = product.Sku,
            barcode     = product.Barcode,
            barcodeSvg  = svg
        }));
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var supplier = await db.Suppliers.FirstOrDefaultAsync(s => s.UserId == SupplierId);
        if (supplier is null) return NotFound(ApiResponse.Fail("Supplier not found."));

        var product = await db.Products.FirstOrDefaultAsync(p => p.Id == id && p.SupplierId == supplier.Id);
        if (product is null) return NotFound(ApiResponse.Fail("Product not found."));

        // Check if product has associated order items — soft-delete instead of hard-delete
        var hasOrders = await db.Set<OrderItem>().AnyAsync(oi => oi.ProductId == id);
        if (hasOrders)
        {
            // Soft-delete: mark as unavailable so order history is preserved
            product.IsAvailable = false;
            product.UpdatedAt = DateTime.UtcNow;
            await db.SaveChangesAsync();
            return Ok(ApiResponse.Ok("Product removed from listing."));
        }

        // No orders reference this product — safe to hard-delete
        // Remove related QR codes first
        var qrCodes = await db.Set<ProductQrCode>().Where(q => q.ProductId == id).ToListAsync();
        if (qrCodes.Count > 0)
            db.Set<ProductQrCode>().RemoveRange(qrCodes);

        db.Products.Remove(product);
        await db.SaveChangesAsync();
        return Ok(ApiResponse.Ok("Product deleted."));
    }
}

public record ProductRequest(
    [Required] string Name,
    [Required] string Sku,
    [Required] decimal Price,
    string? Description,
    string? Barcode,
    Guid? CategoryId,
    int MinOrderQty = 1,
    int StockQty = 0,
    string Unit = "unit",
    string? Images = null,
    bool IsAvailable = true,
    bool IsFoodItem = false
);
