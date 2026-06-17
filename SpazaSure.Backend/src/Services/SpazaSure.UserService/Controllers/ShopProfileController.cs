using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SpazaSure.Infrastructure.Data;
using SpazaSure.Shared.Models;
using System.Security.Claims;

namespace SpazaSure.UserService.Controllers;

[ApiController]
[Route("api/shop/profile")]
[Authorize(Roles = "spaza_owner")]
public class ShopProfileController(SpazaSureDbContext db) : ControllerBase
{
    private Guid UserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    /// <summary>
    /// Get the logged-in spaza owner's profile
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetProfile()
    {
        var shop = await db.SpazaShops
            .Include(s => s.Documents)
            .Include(s => s.User)
            .FirstOrDefaultAsync(s => s.UserId == UserId);

        if (shop is null) return NotFound(ApiResponse.Fail("Shop profile not found."));

        return Ok(ApiResponse<object>.Ok(new
        {
            shop.Id,
            shop.ShopName,
            shop.OwnerName,
            shop.OwnerIdNumber,
            shop.Phone,
            Email = shop.Email ?? shop.User?.Email ?? "",
            shop.Address,
            shop.City,
            shop.Province,
            shop.PostalCode,
            shop.Latitude,
            shop.Longitude,
            shop.Status,
            shop.ComplianceStatus,
            shop.OnboardingFeePaid,
            shop.RatingAvg,
            shop.RatingCount,
            JoinedAt = shop.CreatedAt,
            Documents = shop.Documents.Select(d => new
            {
                d.Id,
                d.DocType,
                d.DocUrl,
                d.Status,
                d.ExpiryDate,
                d.RejectionNote
            })
        }));
    }

    /// <summary>
    /// Update shop profile details
    /// </summary>
    [HttpPut]
    public async Task<IActionResult> UpdateProfile([FromBody] UpdateShopProfileRequest req)
    {
        var shop = await db.SpazaShops.FirstOrDefaultAsync(s => s.UserId == UserId);
        if (shop is null) return NotFound(ApiResponse.Fail("Shop profile not found."));

        if (req.ShopName != null) shop.ShopName = req.ShopName;
        if (req.OwnerName != null) shop.OwnerName = req.OwnerName;
        if (req.Phone != null) shop.Phone = req.Phone;
        if (req.Email != null) shop.Email = req.Email;
        if (req.Address != null) shop.Address = req.Address;
        if (req.City != null) shop.City = req.City;
        if (req.Province != null) shop.Province = req.Province;
        if (req.PostalCode != null) shop.PostalCode = req.PostalCode;

        await db.SaveChangesAsync();
        return Ok(ApiResponse.Ok("Profile updated successfully."));
    }
}

public record UpdateShopProfileRequest(
    string? ShopName, string? OwnerName, string? Phone, string? Email,
    string? Address, string? City, string? Province, string? PostalCode
);
