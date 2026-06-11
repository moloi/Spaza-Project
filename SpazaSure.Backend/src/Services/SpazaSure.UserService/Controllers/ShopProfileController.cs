using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SpazaSure.Infrastructure.Data;
using SpazaSure.Shared.Models;
using System.Security.Claims;

namespace SpazaSure.UserService.Controllers;

[ApiController]
[Route("api/shop/profile")]
[Authorize]
public class ShopProfileController(SpazaSureDbContext db) : ControllerBase
{
    private Guid UserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    /// <summary>
    /// Get the current shop's profile.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> Get()
    {
        var shop = await db.SpazaShops
            .Include(s => s.User)
            .FirstOrDefaultAsync(s => s.UserId == UserId);

        if (shop is null) return NotFound(ApiResponse.Fail("Shop not found."));

        return Ok(ApiResponse<object>.Ok(new
        {
            shop.Id,
            shop.ShopName,
            shop.OwnerName,
            shop.Phone,
            shop.Email,
            shop.Address,
            shop.City,
            shop.Province,
            shop.PostalCode,
            shop.Latitude,
            shop.Longitude,
            shop.Status,
            shop.ComplianceStatus,
            shop.RatingAvg,
            shop.RatingCount,
            shop.OnboardingFeePaid
        }));
    }

    /// <summary>
    /// Update the shop profile.
    /// </summary>
    [HttpPut]
    public async Task<IActionResult> Update([FromBody] UpdateShopProfileRequest req)
    {
        var shop = await db.SpazaShops.FirstOrDefaultAsync(s => s.UserId == UserId);
        if (shop is null) return NotFound(ApiResponse.Fail("Shop not found."));

        shop.ShopName    = req.ShopName    ?? shop.ShopName;
        shop.OwnerName   = req.OwnerName   ?? shop.OwnerName;
        shop.Phone       = req.Phone       ?? shop.Phone;
        shop.Email       = req.Email       ?? shop.Email;
        shop.Address     = req.Address     ?? shop.Address;
        shop.City        = req.City        ?? shop.City;
        shop.Province    = req.Province    ?? shop.Province;
        shop.PostalCode  = req.PostalCode  ?? shop.PostalCode;

        if (req.Latitude.HasValue) shop.Latitude = req.Latitude;
        if (req.Longitude.HasValue) shop.Longitude = req.Longitude;

        await db.SaveChangesAsync();
        return Ok(ApiResponse.Ok("Profile updated."));
    }

    /// <summary>
    /// Upload or update the shop logo/image.
    /// </summary>
    [HttpPost("logo")]
    public async Task<IActionResult> UploadLogo(IFormFile logo)
    {
        if (logo is null || logo.Length == 0) return BadRequest(ApiResponse.Fail("No file provided."));
        var allowed = new[] { ".jpg", ".jpeg", ".png", ".webp" };
        var ext = Path.GetExtension(logo.FileName).ToLowerInvariant();
        if (!allowed.Contains(ext)) return BadRequest(ApiResponse.Fail("Only JPG, PNG and WEBP are allowed."));
        if (logo.Length > 5 * 1024 * 1024) return BadRequest(ApiResponse.Fail("Image must be under 5MB."));

        var shop = await db.SpazaShops.FirstOrDefaultAsync(s => s.UserId == UserId);
        if (shop is null) return NotFound(ApiResponse.Fail("Shop not found."));

        Directory.CreateDirectory(Path.Combine("uploads", "shop-logos"));
        var fn = $"{shop.Id}{ext}";
        await using var stream = System.IO.File.Create(Path.Combine("uploads", "shop-logos", fn));
        await logo.CopyToAsync(stream);

        // Store logo URL on the shop — for now we'll just return it
        // (Would need a LogoUrl column on SpazaShop entity for full persistence)
        var logoUrl = $"/uploads/shop-logos/{fn}";
        await db.SaveChangesAsync();

        return Ok(ApiResponse<object>.Ok(new { logoUrl }));
    }
}

public record UpdateShopProfileRequest(
    string? ShopName, string? OwnerName, string? Phone, string? Email,
    string? Address, string? City, string? Province, string? PostalCode,
    double? Latitude, double? Longitude
);
