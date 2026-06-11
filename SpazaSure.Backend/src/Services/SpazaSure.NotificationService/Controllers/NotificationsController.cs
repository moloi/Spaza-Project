using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SpazaSure.NotificationService.Data;

namespace SpazaSure.NotificationService.Controllers;

[ApiController]
[Route("api/supplier/notifications")]
[Authorize]
public class NotificationsController : ControllerBase
{
    private readonly NotificationDbContext _db;

    public NotificationsController(NotificationDbContext db)
    {
        _db = db;
    }

    private string GetSupplierId() =>
        User.FindFirst("sub")?.Value ?? User.FindFirst("id")?.Value ?? "";

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        var supplierId = GetSupplierId();
        var query = _db.Notifications
            .Where(n => n.SupplierId == supplierId)
            .OrderByDescending(n => n.CreatedAt);

        var total = await query.CountAsync();
        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return Ok(new { data = items, total, page, pageSize });
    }

    [HttpGet("unread-count")]
    public async Task<IActionResult> GetUnreadCount()
    {
        var supplierId = GetSupplierId();
        var count = await _db.Notifications
            .CountAsync(n => n.SupplierId == supplierId && !n.IsRead);
        return Ok(new { count });
    }

    [HttpPut("{id}/read")]
    public async Task<IActionResult> MarkAsRead(Guid id)
    {
        var supplierId = GetSupplierId();
        var notification = await _db.Notifications
            .FirstOrDefaultAsync(n => n.Id == id && n.SupplierId == supplierId);

        if (notification == null) return NotFound();

        notification.IsRead = true;
        await _db.SaveChangesAsync();
        return Ok(new { message = "Marked as read" });
    }

    [HttpPut("read-all")]
    public async Task<IActionResult> MarkAllAsRead()
    {
        var supplierId = GetSupplierId();
        await _db.Notifications
            .Where(n => n.SupplierId == supplierId && !n.IsRead)
            .ExecuteUpdateAsync(s => s.SetProperty(n => n.IsRead, true));
        return Ok(new { message = "All marked as read" });
    }
}
