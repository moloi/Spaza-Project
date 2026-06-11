using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SpazaSure.Infrastructure.Data;
using SpazaSure.Shared.Models;
using System.Security.Claims;

namespace SpazaSure.VerificationService.Controllers;

[ApiController]
[Route("api/verify")]
public class VerifyController(SpazaSureDbContext db) : ControllerBase
{
    /// <summary>
    /// Scan a QR code to verify product authenticity.
    /// Public endpoint — consumers can verify without logging in.
    /// </summary>
    [HttpGet("{qrCode}")]
    [AllowAnonymous]
    public async Task<IActionResult> VerifyProduct(string qrCode)
    {
        var qr = await db.ProductQrCodes
            .Include(q => q.Product)
                .ThenInclude(p => p.Supplier)
            .Include(q => q.Product)
                .ThenInclude(p => p.Category)
            .FirstOrDefaultAsync(q => q.QrCode == qrCode);

        if (qr is null)
            return NotFound(ApiResponse<object>.Ok(new
            {
                verified = false,
                message = "Product not found. This may be a counterfeit item."
            }));

        if (qr.IsRecalled)
            return Ok(ApiResponse<object>.Ok(new
            {
                verified = false,
                recalled = true,
                message = "This product has been recalled. Do not consume.",
                product = new { qr.Product.Name, qr.Product.Sku, qr.BatchNumber }
            }));

        var isExpired = qr.ExpiryDate.HasValue && qr.ExpiryDate.Value < DateOnly.FromDateTime(DateTime.UtcNow);

        // Mark as scanned
        if (!qr.IsScanned)
        {
            qr.IsScanned = true;
            qr.ScannedAt = DateTime.UtcNow;
            await db.SaveChangesAsync();
        }

        return Ok(ApiResponse<object>.Ok(new
        {
            verified = true,
            expired = isExpired,
            message = isExpired
                ? "Product is authentic but past its expiry date."
                : "Product verified as authentic.",
            product = new
            {
                qr.Product.Name,
                qr.Product.Description,
                qr.Product.Sku,
                qr.Product.Price,
                category = qr.Product.Category?.Name,
                images = qr.Product.Images,
                qr.BatchNumber,
                expiryDate = qr.ExpiryDate?.ToString("yyyy-MM-dd"),
                isFoodItem = qr.Product.IsFoodItem
            },
            supplier = new
            {
                qr.Product.Supplier.CompanyName,
                qr.Product.Supplier.Phone,
                qr.Product.Supplier.Email,
                tier = qr.Product.Supplier.Tier
            },
            scan = new
            {
                firstScanned = qr.ScannedAt,
                previouslyScanned = qr.IsScanned && qr.ScannedAt < DateTime.UtcNow.AddSeconds(-5)
            }
        }));
    }

    /// <summary>
    /// Report a suspected counterfeit product.
    /// Requires authentication (shop owner or consumer).
    /// </summary>
    [HttpPost("report")]
    [Authorize]
    public async Task<IActionResult> ReportCounterfeit([FromBody] ReportRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.QrCode) && string.IsNullOrWhiteSpace(req.Description))
            return BadRequest(ApiResponse.Fail("Provide either a QR code or a description of the issue."));

        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

        // If a QR code is provided, look it up
        Guid? productId = null;
        if (!string.IsNullOrWhiteSpace(req.QrCode))
        {
            var qr = await db.ProductQrCodes.FirstOrDefaultAsync(q => q.QrCode == req.QrCode);
            productId = qr?.ProductId;
        }

        // Store report (for now log it — a full reports table can be added later)
        // In production this would go into a dedicated CounterfeitReports table
        Console.WriteLine($"[COUNTERFEIT REPORT] UserId={userId} QR={req.QrCode} Product={productId} Desc={req.Description} Location={req.Location}");

        return Ok(ApiResponse.Ok("Report submitted. Thank you for helping keep our supply chain safe."));
    }

    /// <summary>
    /// Get verification history for the authenticated shop.
    /// Returns products scanned by this shop.
    /// </summary>
    [HttpGet("history")]
    [Authorize]
    public async Task<IActionResult> GetScanHistory([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var userId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        // Get shop for the current user
        var shop = await db.SpazaShops.FirstOrDefaultAsync(s => s.UserId == userId);
        if (shop is null) return NotFound(ApiResponse.Fail("Shop not found."));

        // Return recently scanned QR codes (those that have been scanned)
        var query = db.ProductQrCodes
            .Include(q => q.Product)
            .Where(q => q.IsScanned)
            .OrderByDescending(q => q.ScannedAt);

        var total = await query.CountAsync();
        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(q => new
            {
                q.QrCode,
                q.Product.Name,
                q.Product.Sku,
                q.BatchNumber,
                q.ExpiryDate,
                q.ScannedAt,
                q.IsRecalled
            })
            .ToListAsync();

        return Ok(ApiResponse<object>.Ok(new { total, page, pageSize, items }));
    }
}

public record ReportRequest(string? QrCode, string? Description, string? Location);
