using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SpazaSure.Infrastructure.Data;
using SpazaSure.Infrastructure.Entities;
using SpazaSure.Shared.Models;
using System.Security.Claims;

namespace SpazaSure.ComplianceService.Controllers;

[ApiController]
[Route("api/shop/compliance")]
[Authorize]
public class ShopComplianceController(SpazaSureDbContext db) : ControllerBase
{
    private Guid UserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    /// <summary>
    /// Get the shop's compliance documents.
    /// </summary>
    [HttpGet("documents")]
    public async Task<IActionResult> GetDocuments()
    {
        var shop = await db.SpazaShops
            .Include(s => s.Documents)
            .FirstOrDefaultAsync(s => s.UserId == UserId);

        if (shop is null) return NotFound(ApiResponse.Fail("Shop not found."));

        var docs = shop.Documents.Select(d => new
        {
            d.Id,
            d.DocType,
            d.DocUrl,
            d.Status,
            expiryDate = d.ExpiryDate?.ToString("yyyy-MM-dd"),
            d.RejectionNote,
            d.GuidanceUrl
        });

        return Ok(ApiResponse<object>.Ok(new { documents = docs }));
    }

    /// <summary>
    /// Get overall compliance status for the shop.
    /// </summary>
    [HttpGet("status")]
    public async Task<IActionResult> GetStatus()
    {
        var shop = await db.SpazaShops
            .Include(s => s.Documents)
            .FirstOrDefaultAsync(s => s.UserId == UserId);

        if (shop is null) return NotFound(ApiResponse.Fail("Shop not found."));

        var requiredDocTypes = new[] { "business_license", "health_permit", "food_handler", "id_copy", "proof_of_address" };
        var documents = shop.Documents.ToList();

        var approved = documents.Count(d => d.Status == "approved");
        var pending = documents.Count(d => d.Status == "pending");
        var missing = requiredDocTypes.Length - documents.Count;
        if (missing < 0) missing = 0;

        var overallStatus = approved == requiredDocTypes.Length ? "green"
            : approved + pending >= requiredDocTypes.Length ? "orange"
            : "red";

        return Ok(ApiResponse<object>.Ok(new
        {
            overallStatus,
            complianceStatus = shop.ComplianceStatus,
            totalRequired = requiredDocTypes.Length,
            approved,
            pending,
            missing,
            documents = documents.Select(d => new
            {
                d.Id,
                d.DocType,
                d.DocUrl,
                d.Status,
                expiryDate = d.ExpiryDate?.ToString("yyyy-MM-dd"),
                d.RejectionNote,
                d.GuidanceUrl
            })
        }));
    }

    /// <summary>
    /// Upload a compliance document.
    /// </summary>
    [HttpPost("documents")]
    public async Task<IActionResult> UploadDocument([FromForm] string docType, IFormFile file)
    {
        var shop = await db.SpazaShops.FirstOrDefaultAsync(s => s.UserId == UserId);
        if (shop is null) return NotFound(ApiResponse.Fail("Shop not found."));

        if (file is null || file.Length == 0)
            return BadRequest(ApiResponse.Fail("No file provided."));

        var uploadsDir = Path.Combine("uploads", "shop-docs", shop.Id.ToString());
        Directory.CreateDirectory(uploadsDir);
        var fileName = $"{docType}_{DateTime.UtcNow:yyyyMMddHHmmss}{Path.GetExtension(file.FileName)}";
        await using var stream = System.IO.File.Create(Path.Combine(uploadsDir, fileName));
        await file.CopyToAsync(stream);

        var docUrl = $"/uploads/shop-docs/{shop.Id}/{fileName}";

        // Upsert document
        var existing = await db.ShopDocuments
            .FirstOrDefaultAsync(d => d.ShopId == shop.Id && d.DocType == docType);

        if (existing is not null)
        {
            existing.DocUrl = docUrl;
            existing.Status = "pending";
            existing.RejectionNote = null;
        }
        else
        {
            db.ShopDocuments.Add(new ShopDocument
            {
                ShopId = shop.Id,
                DocType = docType,
                DocUrl = docUrl,
                Status = "pending"
            });
        }

        await db.SaveChangesAsync();
        return Ok(ApiResponse<object>.Ok(new { docType, docUrl, status = "pending" }));
    }
}
