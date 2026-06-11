using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SpazaSure.Infrastructure.Data;
using SpazaSure.Shared.Models;
using System.Security.Claims;

namespace SpazaSure.OrderService.Controllers;

[ApiController]
[Route("api/shop/orders")]
[Authorize]
public class RatingsController(SpazaSureDbContext db) : ControllerBase
{
    private Guid UserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    /// <summary>
    /// Rate a supplier after delivery is confirmed.
    /// </summary>
    [HttpPost("{orderId:guid}/rate")]
    public async Task<IActionResult> RateSupplier(Guid orderId, [FromBody] RateRequest req)
    {
        var shop = await db.SpazaShops.FirstOrDefaultAsync(s => s.UserId == UserId);
        if (shop is null) return NotFound(ApiResponse.Fail("Shop not found."));

        var order = await db.Orders
            .Include(o => o.Supplier)
            .FirstOrDefaultAsync(o => o.Id == orderId && o.ShopId == shop.Id);

        if (order is null) return NotFound(ApiResponse.Fail("Order not found."));
        if (order.Status != "delivered")
            return BadRequest(ApiResponse.Fail("Can only rate delivered orders."));

        if (req.Rating < 1 || req.Rating > 5)
            return BadRequest(ApiResponse.Fail("Rating must be between 1 and 5."));

        // Update supplier's average rating (simple running average)
        // In production, store individual ratings in a reviews table
        var supplier = order.Supplier;
        var totalRatingPoints = supplier.CommissionRate; // Reusing as placeholder — see note below

        // For now, log the rating. A proper implementation needs a Reviews table.
        Console.WriteLine($"[RATING] Order={orderId} Supplier={supplier.Id} Rating={req.Rating} Comment={req.Comment}");

        return Ok(ApiResponse.Ok("Thank you for your rating!"));
    }

    /// <summary>
    /// Rate delivery experience.
    /// </summary>
    [HttpPost("{orderId:guid}/rate-delivery")]
    public async Task<IActionResult> RateDelivery(Guid orderId, [FromBody] RateRequest req)
    {
        var shop = await db.SpazaShops.FirstOrDefaultAsync(s => s.UserId == UserId);
        if (shop is null) return NotFound(ApiResponse.Fail("Shop not found."));

        var order = await db.Orders.FirstOrDefaultAsync(o => o.Id == orderId && o.ShopId == shop.Id);
        if (order is null) return NotFound(ApiResponse.Fail("Order not found."));
        if (order.Status != "delivered")
            return BadRequest(ApiResponse.Fail("Can only rate delivered orders."));

        if (req.Rating < 1 || req.Rating > 5)
            return BadRequest(ApiResponse.Fail("Rating must be between 1 and 5."));

        Console.WriteLine($"[DELIVERY RATING] Order={orderId} Rating={req.Rating} Comment={req.Comment}");

        return Ok(ApiResponse.Ok("Thank you for rating the delivery!"));
    }
}

public record RateRequest(int Rating, string? Comment);
