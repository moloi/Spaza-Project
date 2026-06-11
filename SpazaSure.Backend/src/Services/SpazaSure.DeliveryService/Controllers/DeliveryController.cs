using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SpazaSure.Infrastructure.Data;
using SpazaSure.Shared.Models;
using System.Security.Claims;

namespace SpazaSure.DeliveryService.Controllers;

[ApiController]
[Route("api/shop/delivery")]
[Authorize]
public class DeliveryController(SpazaSureDbContext db) : ControllerBase
{
    private Guid UserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    /// <summary>
    /// Get delivery status for a specific order.
    /// </summary>
    [HttpGet("{orderId:guid}")]
    public async Task<IActionResult> GetDeliveryStatus(Guid orderId)
    {
        var shop = await db.SpazaShops.FirstOrDefaultAsync(s => s.UserId == UserId);
        if (shop is null) return NotFound(ApiResponse.Fail("Shop not found."));

        var order = await db.Orders
            .Include(o => o.Supplier)
            .FirstOrDefaultAsync(o => o.Id == orderId && o.ShopId == shop.Id);

        if (order is null) return NotFound(ApiResponse.Fail("Order not found."));

        // Determine delivery stage based on order status
        var stage = order.Status switch
        {
            "pending" => "awaiting_confirmation",
            "processing" => "preparing",
            "dispatched" => "in_transit",
            "delivered" => "delivered",
            "cancelled" => "cancelled",
            _ => "unknown"
        };

        return Ok(ApiResponse<object>.Ok(new
        {
            orderId = order.Id,
            orderNumber = order.OrderNumber,
            status = order.Status,
            deliveryStage = stage,
            deliveryType = order.DeliveryType,
            deliveryAddress = order.DeliveryAddress,
            supplier = new
            {
                name = order.Supplier.CompanyName,
                phone = order.Supplier.Phone
            },
            estimatedDelivery = order.Status == "dispatched"
                ? DateTime.UtcNow.AddHours(2).ToString("o")
                : null,
            updatedAt = order.UpdatedAt
        }));
    }

    /// <summary>
    /// Get all active deliveries for the current shop.
    /// </summary>
    [HttpGet("active")]
    public async Task<IActionResult> GetActiveDeliveries()
    {
        var shop = await db.SpazaShops.FirstOrDefaultAsync(s => s.UserId == UserId);
        if (shop is null) return NotFound(ApiResponse.Fail("Shop not found."));

        var activeStatuses = new[] { "processing", "dispatched" };
        var deliveries = await db.Orders
            .Include(o => o.Supplier)
            .Include(o => o.Items)
            .Where(o => o.ShopId == shop.Id && activeStatuses.Contains(o.Status))
            .OrderByDescending(o => o.UpdatedAt)
            .Select(o => new
            {
                orderId = o.Id,
                orderNumber = o.OrderNumber,
                status = o.Status,
                deliveryType = o.DeliveryType,
                supplierName = o.Supplier.CompanyName,
                supplierPhone = o.Supplier.Phone,
                itemCount = o.Items.Count,
                totalAmount = o.TotalAmount,
                createdAt = o.CreatedAt,
                updatedAt = o.UpdatedAt
            })
            .ToListAsync();

        return Ok(ApiResponse<object>.Ok(new { deliveries }));
    }

    /// <summary>
    /// Confirm delivery receipt (shop owner confirms they received the goods).
    /// </summary>
    [HttpPost("{orderId:guid}/confirm")]
    public async Task<IActionResult> ConfirmDelivery(Guid orderId)
    {
        var shop = await db.SpazaShops.FirstOrDefaultAsync(s => s.UserId == UserId);
        if (shop is null) return NotFound(ApiResponse.Fail("Shop not found."));

        var order = await db.Orders.FirstOrDefaultAsync(o => o.Id == orderId && o.ShopId == shop.Id);
        if (order is null) return NotFound(ApiResponse.Fail("Order not found."));

        if (order.Status != "dispatched")
            return BadRequest(ApiResponse.Fail($"Cannot confirm delivery for order in '{order.Status}' status."));

        order.Status = "delivered";
        await db.SaveChangesAsync();

        return Ok(ApiResponse<object>.Ok(new
        {
            orderId = order.Id,
            orderNumber = order.OrderNumber,
            status = order.Status,
            deliveredAt = order.UpdatedAt
        }));
    }

    /// <summary>
    /// Get delivery history for the current shop.
    /// </summary>
    [HttpGet("history")]
    public async Task<IActionResult> GetDeliveryHistory([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var shop = await db.SpazaShops.FirstOrDefaultAsync(s => s.UserId == UserId);
        if (shop is null) return NotFound(ApiResponse.Fail("Shop not found."));

        var query = db.Orders
            .Include(o => o.Supplier)
            .Where(o => o.ShopId == shop.Id && o.Status == "delivered")
            .OrderByDescending(o => o.UpdatedAt);

        var total = await query.CountAsync();
        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(o => new
            {
                orderId = o.Id,
                orderNumber = o.OrderNumber,
                supplierName = o.Supplier.CompanyName,
                totalAmount = o.TotalAmount,
                deliveryType = o.DeliveryType,
                deliveredAt = o.UpdatedAt
            })
            .ToListAsync();

        return Ok(ApiResponse<object>.Ok(new { total, page, pageSize, items }));
    }
}
