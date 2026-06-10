using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SpazaSure.Infrastructure.Data;
using SpazaSure.Shared.Models;

namespace SpazaSure.ComplianceService.Controllers;

[ApiController]
[Route("api/compliance/documents")]
[Authorize]
public class ComplianceController(SpazaSureDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] string? status, [FromQuery] string? search)
    {
        var query = db.SupplierDocuments
            .Include(d => d.Supplier)
            .AsQueryable();

        if (!string.IsNullOrEmpty(status) && status != "all")
            query = query.Where(d => d.Status == status);

        if (!string.IsNullOrEmpty(search))
            query = query.Where(d =>
                d.Supplier.CompanyName.Contains(search) ||
                d.Supplier.Email.Contains(search) ||
                d.DocType.Contains(search));

        var docs = await query.OrderByDescending(d => d.CreatedAt).Select(d => new
        {
            d.Id,
            d.DocType,
            d.DocUrl,
            d.Status,
            d.ExpiryDate,
            d.RejectionNote,
            d.CreatedAt,
            SupplierId   = d.Supplier.Id,
            SupplierName = d.Supplier.CompanyName,
            SupplierEmail = d.Supplier.Email,
        }).ToListAsync();

        var pending  = docs.Count(d => d.Status == "pending");
        var approved = docs.Count(d => d.Status == "approved");
        var rejected = docs.Count(d => d.Status == "rejected");

        return Ok(ApiResponse<object>.Ok(new { docs, summary = new { pending, approved, rejected } }));
    }

    [HttpGet("shop")]
    public async Task<IActionResult> GetShopDocs([FromQuery] string? status, [FromQuery] string? search)
    {
        var query = db.ShopDocuments
            .Include(d => d.Shop)
            .AsQueryable();

        if (!string.IsNullOrEmpty(status) && status != "all")
            query = query.Where(d => d.Status == status);

        if (!string.IsNullOrEmpty(search))
            query = query.Where(d =>
                d.Shop.ShopName.Contains(search) ||
                (d.Shop.Email != null && d.Shop.Email.Contains(search)) ||
                d.DocType.Contains(search));

        var docs = await query.OrderByDescending(d => d.CreatedAt).Select(d => new
        {
            d.Id,
            d.DocType,
            d.DocUrl,
            d.Status,
            d.ExpiryDate,
            d.RejectionNote,
            d.CreatedAt,
            SupplierId   = d.Shop.Id,
            SupplierName = d.Shop.ShopName,
            SupplierEmail = d.Shop.Email ?? d.Shop.Phone,
        }).ToListAsync();

        var pending  = docs.Count(d => d.Status == "pending");
        var approved = docs.Count(d => d.Status == "approved");
        var rejected = docs.Count(d => d.Status == "rejected");

        return Ok(ApiResponse<object>.Ok(new { docs, summary = new { pending, approved, rejected } }));
    }

    [HttpPatch("{id}/approve")]
    public async Task<IActionResult> Approve(Guid id)
    {
        // Try supplier documents first
        var doc = await db.SupplierDocuments.FindAsync(id);
        if (doc is not null)
        {
            doc.Status = "approved";
            doc.RejectionNote = null;
            await db.SaveChangesAsync();
            return Ok(ApiResponse.Ok("Document approved."));
        }

        // Try shop documents
        var shopDoc = await db.ShopDocuments.FindAsync(id);
        if (shopDoc is null) return NotFound(ApiResponse.Fail("Document not found."));

        shopDoc.Status = "approved";
        shopDoc.RejectionNote = null;
        await db.SaveChangesAsync();

        return Ok(ApiResponse.Ok("Document approved."));
    }

    [HttpPatch("{id}/reject")]
    public async Task<IActionResult> Reject(Guid id, RejectRequest req)
    {
        // Try supplier documents first
        var doc = await db.SupplierDocuments.FindAsync(id);
        if (doc is not null)
        {
            doc.Status = "rejected";
            doc.RejectionNote = req.Reason;
            await db.SaveChangesAsync();
            return Ok(ApiResponse.Ok("Document rejected."));
        }

        // Try shop documents
        var shopDoc = await db.ShopDocuments.FindAsync(id);
        if (shopDoc is null) return NotFound(ApiResponse.Fail("Document not found."));

        shopDoc.Status = "rejected";
        shopDoc.RejectionNote = req.Reason;
        await db.SaveChangesAsync();

        return Ok(ApiResponse.Ok("Document rejected."));
    }
}

public record RejectRequest(string Reason);
