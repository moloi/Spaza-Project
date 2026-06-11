using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SpazaSure.NotificationService.Data;

namespace SpazaSure.NotificationService.Controllers;

[ApiController]
[Route("api/shop/notifications")]
[Authorize]
public class ShopNotificationsController : ControllerBase
{
    private readonly NotificationDbContext _db;

    public ShopNotificationsController(NotificationDbContext db)
    {
        _db = db;
    }

    private string GetShopId() =>
        User.FindFirst("sub")?.Value ?? User.FindFirst("id")?.Value ?? "";

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var shopId = GetShopId();
        var query = _db.Notifications
            .Where(n => n.SupplierId == shopId) // Reusing SupplierId field as recipient ID
            .OrderByDescending(n => n.CreatedAt);

        var total = await query.CountAsync();
        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return Ok(new { success = true, data = new { items, total, page, pageSize } });
    }

    [HttpGet("unread-count")]
    public async Task<IActionResult> GetUnreadCount()
    {
        var shopId = GetShopId();
        var count = await _db.Notifications
            .CountAsync(n => n.SupplierId == shopId && !n.IsRead);
        return Ok(new { success = true, data = new { count } });
    }

    [HttpPatch("{id:guid}/read")]
    public async Task<IActionResult> MarkAsRead(Guid id)
    {
        var shopId = GetShopId();
        var notification = await _db.Notifications
            .FirstOrDefaultAsync(n => n.Id == id && n.SupplierId == shopId);

        if (notification == null) return NotFound(new { success = false, message = "Notification not found." });

        notification.IsRead = true;
        await _db.SaveChangesAsync();
        return Ok(new { success = true, message = "Marked as read" });
    }

    [HttpPatch("read-all")]
    public async Task<IActionResult> MarkAllAsRead()
    {
        var shopId = GetShopId();
        await _db.Notifications
            .Where(n => n.SupplierId == shopId && !n.IsRead)
            .ExecuteUpdateAsync(s => s.SetProperty(n => n.IsRead, true));
        return Ok(new { success = true, message = "All marked as read" });
    }

    /// <summary>
    /// Register a device FCM token for push notifications.
    /// </summary>
    [HttpPost("register-device")]
    public async Task<IActionResult> RegisterDevice([FromBody] RegisterDeviceRequest req)
    {
        if (string.IsNullOrWhiteSpace(req.FcmToken))
            return BadRequest(new { success = false, message = "FCM token is required." });

        var shopId = GetShopId();

        // Store the FCM token (in production, use a dedicated DeviceTokens table)
        // For now, log it so we know the registration flow works
        Console.WriteLine($"[FCM] Registered device token for shop {shopId}: {req.FcmToken[..20]}...");

        return Ok(new { success = true, message = "Device registered for push notifications." });
    }
}

public record RegisterDeviceRequest(string FcmToken, string? Platform);
